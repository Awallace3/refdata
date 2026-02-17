#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FIT_DIR="$SCRIPT_DIR"

BASE_DIR=""
DIN_FILE="${SCRIPT_DIR}/../10_din/kb49.din"
STRUCT_DIR="${SCRIPT_DIR}/../20_kb49"
DIR_TEMPLATE="{base}/{method}/{basis}"
READER_SCRIPT="reader_psi4.m"
OCTAVE_BIN="octave-cli"
CSV_OUT=""

usage() {
  cat <<'EOF'
Usage:
  run_psi4_a1a2_fits.sh --base-dir <path> [options]

Required:
  --base-dir <path>         Base directory with psi4 result folders.
                            Created automatically if it does not exist.

Optional:
  --din <path>              DIN file (default: ../10_din/kb49.din)
  --struct-dir <path>       Structure directory (default: ../20_kb49)
  --dir-template <pattern>  Directory template for each method/basis.
                            Tokens: {base}, {method}, {basis}
                            Default: {base}/{method}/{basis}
  --reader <file>           Reader script in 50_fit (reader_psi4.m or
                            reader_postg_psi4.m). Default: reader_psi4.m
  --octave <bin>            Octave executable (default: octave-cli)
  --csv-out <path>          Optional CSV output file
  -h, --help                Show this help message.

Notes:
  - Basis names are used verbatim. If your directory naming differs,
    provide a custom --dir-template.
  - This script uses the listed a1/a2 values as initial guesses for fitting.
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
    --reader)
      READER_SCRIPT="$2"
      shift 2
      ;;
    --octave)
      OCTAVE_BIN="$2"
      shift 2
      ;;
    --csv-out)
      CSV_OUT="$2"
      shift 2
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

if [[ ! -d "$BASE_DIR" ]]; then
  mkdir -p -- "$BASE_DIR"
fi
if [[ ! -f "$DIN_FILE" ]]; then
  printf 'Error: DIN file does not exist: %s\n' "$DIN_FILE" >&2
  exit 2
fi
if [[ ! -d "$STRUCT_DIR" ]]; then
  printf 'Error: structure directory does not exist: %s\n' "$STRUCT_DIR" >&2
  exit 2
fi
if [[ ! -f "$FIT_DIR/$READER_SCRIPT" ]]; then
  printf 'Error: reader script not found: %s\n' "$FIT_DIR/$READER_SCRIPT" >&2
  exit 2
fi

build_result_dir() {
  local method="$1"
  local basis="$2"
  local out="$DIR_TEMPLATE"
  out="${out//\{base\}/$BASE_DIR}"
  out="${out//\{method\}/$method}"
  out="${out//\{basis\}/$basis}"
  printf '%s' "$out"
}

csv_escape() {
  local value="$1"
  value="${value//\"/\"\"}"
  printf '"%s"' "$value"
}

write_csv_row() {
  local status="$1"
  local combo="$2"
  local a1_fit="$3"
  local a2_fit="$4"
  local mad="$5"
  local mapd="$6"
  local npts="$7"
  local result_dir="$8"

  [[ -z "$CSV_OUT" ]] && return 0
  printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$(csv_escape "$status")" \
    "$(csv_escape "$combo")" \
    "$(csv_escape "$a1_fit")" \
    "$(csv_escape "$a2_fit")" \
    "$(csv_escape "$mad")" \
    "$(csv_escape "$mapd")" \
    "$(csv_escape "$npts")" \
    "$(csv_escape "$result_dir")" >> "$CSV_OUT"
}

if [[ -n "$CSV_OUT" ]]; then
  csv_parent="$(dirname -- "$CSV_OUT")"
  if [[ ! -d "$csv_parent" ]]; then
    printf 'Error: parent directory for --csv-out does not exist: %s\n' "$csv_parent" >&2
    exit 2
  fi
  printf 'status,combo,a1_fit,a2_fit,MAD,MAPD,n,result_dir\n' > "$CSV_OUT"
fi

tmp_m="$(mktemp)"
trap 'rm -f "$tmp_m"' EXIT

cat > "$tmp_m" <<'EOF'
warning("off");
pkg load optim;

fit_dir = getenv("FIT_DIR");
addpath(fit_dir);

source(fullfile(fit_dir, getenv("READER_SCRIPT")));
source(fullfile(fit_dir, "energy_bj.m"));

global hy2kcal e n xc z c6 c8 c10 c9 rc dimers mol1 mol2 be_ref active usec9
hy2kcal = 627.51;
usec9 = 0;

din = getenv("DIN_FILE");
dir_s = getenv("STRUCT_DIR");
result_dir = getenv("RESULT_DIR");
method = getenv("METHOD_NAME");
basis = getenv("BASIS_NAME");

a1 = str2double(getenv("A1_INIT"));
a2 = str2double(getenv("A2_INIT"));

[n, rr] = load_din(din);
dimers = {};
be_ref = struct();
for i = 1:length(rr)
  dimers{end+1} = rr{i}{2};
  be_ref = setfield(be_ref, rr{i}{2}, abs(rr{i}{7}));
endfor

dir_e = {result_dir};
source(fullfile(fit_dir, "collect_for_fit.m"));

if (length(dimers) == 0)
  fprintf(2, "SKIP\t%s/%s\tno active dimers\t%s\n", method, basis, result_dir);
  exit(3);
endif

pin = [a1, a2];
source(fullfile(fit_dir, "fit_quiet.m"));

mad = mean(abs(yout - yin));
mapd = mean(abs((yout - yin) ./ yin)) * 100;
printf("OK\t%s/%s\t%.6f\t%.6f\t%.6f\t%.6f\t%d\t%s\n", method, basis, pout(1), pout(2), mad, mapd, length(yin), result_dir);
EOF

printf 'status\tcombo\ta1_fit\ta2_fit\tMAD\tMAPD\tn\tresult_dir\n'

while IFS='|' read -r method basis a1_init a2_init; do
  [[ -z "$method" ]] && continue
  result_dir="$(build_result_dir "$method" "$basis")"

  if [[ ! -d "$result_dir" ]]; then
    combo="$method/$basis"
    printf 'MISS\t%s\t-\t-\t-\t-\t-\t%s\n' "$combo" "$result_dir"
    write_csv_row "MISS" "$combo" "-" "-" "-" "-" "-" "$result_dir"
    continue
  fi

  set +e
  oct_out="$({
    FIT_DIR="$FIT_DIR" \
    DIN_FILE="$DIN_FILE" \
    STRUCT_DIR="$STRUCT_DIR" \
    READER_SCRIPT="$READER_SCRIPT" \
    RESULT_DIR="$result_dir" \
    METHOD_NAME="$method" \
    BASIS_NAME="$basis" \
    A1_INIT="$a1_init" \
    A2_INIT="$a2_init" \
    "$OCTAVE_BIN" -q "$tmp_m"
  } 2>&1)"
  oct_rc=$?
  set -e

  row_line="$(printf '%s\n' "$oct_out" | awk -F'\t' '/^(OK|SKIP)\t/ {line=$0} END {print line}')"
  if [[ -n "$row_line" ]]; then
    printf '%s\n' "$row_line"
    IFS=$'\t' read -r status combo a1_fit a2_fit mad mapd npts row_result_dir <<< "$row_line"
    write_csv_row "$status" "$combo" "$a1_fit" "$a2_fit" "$mad" "$mapd" "$npts" "$row_result_dir"
  else
    combo="$method/$basis"
    printf 'FAIL\t%s\t-\t-\t-\t-\t-\t%s\n' "$combo" "$result_dir"
    write_csv_row "FAIL" "$combo" "-" "-" "-" "-" "-" "$result_dir"
    if [[ -n "$oct_out" ]]; then
      printf '%s\n' "$oct_out" >&2
    fi
  fi
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
