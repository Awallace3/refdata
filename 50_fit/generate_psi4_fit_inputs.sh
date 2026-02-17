#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

BASE_DIR=""
DIN_FILE="${SCRIPT_DIR}/../10_din/kb49.din"
STRUCT_DIR="${SCRIPT_DIR}/../20_kb49"
DIR_TEMPLATE="{base}/{method}/{basis}"
MEMORY="2 GB"
THREADS="6"
OVERWRITE=0

usage() {
  cat <<'EOF'
Usage:
  generate_psi4_fit_inputs.sh --base-dir <path> [options]

Required:
  --base-dir <path>         Root directory for generated inputs.

Optional:
  --din <path>              DIN file (default: ../10_din/kb49.din)
  --struct-dir <path>       XYZ structure directory (default: ../20_kb49)
  --dir-template <pattern>  Directory template per method/basis.
                            Tokens: {base}, {method}, {basis}
                            Default: {base}/{method}/{basis}
  --memory <value>          Psi4 memory line value (default: "2 GB")
  --threads <n>             set_num_threads value (default: 6)
  --overwrite               Replace existing .dat input files
  -h, --help                Show help

Notes:
  - Uses the molecules listed in the DIN file, matching 40_gen/make_inputs.m logic.
  - Generates one Psi4 input file per molecule as <name>.dat in each combo directory.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir)
      BASE_DIR="$2"
      shift 2
      ;;
    --din)
      DIN_FILE="$2"
      shift 2
      ;;
    --struct-dir)
      STRUCT_DIR="$2"
      shift 2
      ;;
    --dir-template)
      DIR_TEMPLATE="$2"
      shift 2
      ;;
    --memory)
      MEMORY="$2"
      shift 2
      ;;
    --threads)
      THREADS="$2"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$BASE_DIR" ]]; then
  printf 'Error: --base-dir is required.\n\n' >&2
  usage >&2
  exit 2
fi

if [[ ! -f "$DIN_FILE" ]]; then
  printf 'Error: DIN file not found: %s\n' "$DIN_FILE" >&2
  exit 2
fi
if [[ ! -d "$STRUCT_DIR" ]]; then
  printf 'Error: structure directory not found: %s\n' "$STRUCT_DIR" >&2
  exit 2
fi

mkdir -p -- "$BASE_DIR"

build_result_dir() {
  local method="$1"
  local basis="$2"
  local out="$DIR_TEMPLATE"
  out="${out//\{base\}/$BASE_DIR}"
  out="${out//\{method\}/$method}"
  out="${out//\{basis\}/$basis}"
  printf '%s' "$out"
}

tmp_names="$(mktemp)"
trap 'rm -f "$tmp_names"' EXIT

awk '
  BEGIN { mode = "coef" }
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  {
    line = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

    if (mode == "coef") {
      if (line == "0") {
        mode = "ref"
      } else {
        mode = "name"
      }
      next
    }

    if (mode == "name") {
      if (!(line in seen)) {
        print line
        seen[line] = 1
      }
      mode = "coef"
      next
    }

    if (mode == "ref") {
      mode = "coef"
      next
    }
  }
' "$DIN_FILE" > "$tmp_names"

if [[ ! -s "$tmp_names" ]]; then
  printf 'Error: no molecule names parsed from DIN: %s\n' "$DIN_FILE" >&2
  exit 2
fi

make_input() {
  local xyz_file="$1"
  local out_file="$2"
  local method="$3"
  local basis="$4"
  local molname="$5"

  local nat q m line
  nat="$(awk 'NR==1{print $1}' "$xyz_file")"
  line="$(awk 'NR==2{print $0}' "$xyz_file")"

  q="$(printf '%s\n' "$line" | awk '{if (NF>=2 && $1 ~ /^[-+]?[0-9]+$/ && $2 ~ /^[-+]?[0-9]+$/) print $1; else print 0}')"
  m="$(printf '%s\n' "$line" | awk '{if (NF>=2 && $1 ~ /^[-+]?[0-9]+$/ && $2 ~ /^[-+]?[0-9]+$/) print $2; else print 1}')"

  {
    printf 'memory %s\n' "$MEMORY"
    printf 'set_num_threads(%s)\n\n' "$THREADS"
    printf 'molecule %s {\n' "$molname"
    printf '%s %s\n' "$q" "$m"
    awk 'NR>=3 {print}' "$xyz_file"
    printf 'units angstrom\n'
    printf 'no_reorient\n'
    printf 'symmetry c1\n'
    printf '}\n\n'
    printf 'set scf {\n'
    printf '  scf_type df\n'
    printf '  dft_spherical_points 590\n'
    printf '  dft_radial_points 99\n'
    printf '}\n\n'
    printf 'set {\n'
    printf '  basis %s\n' "$basis"
    printf '  puream false\n'
    printf '  writer_file_label %s\n' "$molname"
    printf '  model_write true \n'
    printf '}\n\n'
    printf "energy('%s')\n" "$method"
  } > "$out_file"

  if [[ -n "$nat" && "$nat" =~ ^[0-9]+$ ]]; then
    real_nat="$(awk 'NR>=3 && NF>=4 {n++} END {print n+0}' "$xyz_file")"
    if [[ "$real_nat" -ne "$nat" ]]; then
      printf 'Warning: atom count mismatch for %s (declared %s, found %s)\n' "$xyz_file" "$nat" "$real_nat" >&2
    fi
  fi
}

printf 'status\tcombo\tmolecules\tdirectory\n'

while IFS='|' read -r method basis _a1 _a2; do
  [[ -z "$method" ]] && continue
  combo="$method/$basis"
  combo_dir="$(build_result_dir "$method" "$basis")"
  mkdir -p -- "$combo_dir"

  count=0
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    xyz_file="$STRUCT_DIR/$name.xyz"
    if [[ ! -f "$xyz_file" ]]; then
      printf 'Error: missing XYZ file: %s\n' "$xyz_file" >&2
      exit 2
    fi
    out_file="$combo_dir/$name.dat"
    if [[ "$OVERWRITE" -eq 0 && -f "$out_file" ]]; then
      continue
    fi
    make_input "$xyz_file" "$out_file" "$method" "$basis" "$name"
    count=$((count + 1))
  done < "$tmp_names"

  printf 'OK\t%s\t%d\t%s\n' "$combo" "$count" "$combo_dir"
done <<'EOF'
b3lyp|6-31+g*|0.4515|2.1357
b3lyp|6-31+g**|0.4306|2.2076
b3lyp|6-311+g(2d,2p)|0.4376|2.1607
b3lyp|aug-cc-pvdz|0.6224|1.7068
b3lyp|aug-cc-pvtz|0.6356|1.5119
pw86pbe|6-31+g*|0.6336|1.9148
pw86pbe|6-31+g**|0.6935|1.7519
pw86pbe|aug-cc-pvdz|0.6736|1.9327
pw86pbe|aug-cc-pvtz|0.7564|1.4545
pbe|6-31+g*|0.2445|3.2596
pbe|6-31+g**|0.2746|3.1857
pbe|aug-cc-pvdz|0.2061|3.5486
pbe|aug-cc-pvtz|0.4492|2.5517
pbe0|6-31+g*|0.0845|3.7940
pbe0|6-31+g**|0.1163|3.7191
pbe0|aug-cc-pvdz|0.1389|3.8310
pbe0|aug-cc-pvtz|0.4186|2.6791
blyp|6-31+g*|0.5942|1.4555
blyp|6-31+g**|0.5653|1.5460
blyp|aug-cc-pvdz|0.9742|0.3427
blyp|aug-cc-pvtz|0.7647|0.8457
bhahlyp|6-31+g*|0.1483|3.3435
bhahlyp|6-31+g**|0.1432|3.3705
bhandh|aug-cc-pvtz|0.5610|1.9894
bhandhlyp|aug-cc-pvtz|0.5610|1.9894
bhalfandhalf|aug-cc-pvtz|0.5610|1.9894
bhalfandhalf|aug-cc-pvdz|0.1247|3.5725
cam-b3lyp|6-31+g*|0.2315|3.2123
cam-b3lyp|6-31+g**|0.2365|3.2081
cam-b3lyp|aug-cc-pvdz|0.1849|3.5140
cam-b3lyp|aug-cc-pvtz|0.3248|2.8607
camb3lyp|aug-cc-pvtz|0.3248|2.8607
camb3lyp|aug-cc-pvdz|0.1849|3.5140
lc-wpbe|aug-cc-pvtz|1.0149|0.6755
lcwpbe|aug-cc-pvtz|1.0149|0.6755
lc-wpbe|6-31+g*|0.8134|1.3736
lcwpbe|6-31+g*|0.8134|1.3736
lc-wpbe|6-31+g**|0.8934|1.1466
lcwpbe|6-31+g**|0.8934|1.1466
lcwpbe|aug-cc-pvdz|1.1800|0.4179
b971|aug-cc-pvtz|0.1998|3.5367
b97-1|aug-cc-pvtz|0.1998|3.5367
b97-1|6-31+g*|0.0118|4.1784
b97-1|6-31+g**|0.0429|4.1090
hf|aug-cc-pvdz|0.3698|2.1961
hf|aug-cc-pvtz|0.3698|2.1961
b86bpbe|aug-cc-pvtz|0.7839|1.2544
tpss|aug-cc-pvtz|0.6612|1.5111
hse06|aug-cc-pvtz|0.3691|2.8793
EOF
