#!/usr/bin/env bash

set -euo pipefail

BASE_DIR=""
PSI4_BIN="psi4"
RECURSIVE=0
OVERWRITE=0
KEEP_INPUT_COPY=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  run_psi4_dat_batch.sh --base-dir <path> [options]

Required:
  --base-dir <path>      Directory containing .dat Psi4 input files.

Optional:
  --psi4 <bin>           Psi4 executable (default: psi4)
  --recursive            Include .dat files in subdirectories
  --overwrite            Re-run even if output already looks complete
  --no-keep-input-copy   Do not keep a .input backup copy
  --dry-run              Print commands without running Psi4
  -h, --help             Show help

Behavior:
  - Each <name>.dat is treated as input and output target.
  - A temporary copy is used as the actual input so output can be written
    back to <name>.dat.
  - By default, an original input backup is saved as <name>.dat.input once.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir)
      BASE_DIR="$2"
      shift 2
      ;;
    --psi4)
      PSI4_BIN="$2"
      shift 2
      ;;
    --recursive)
      RECURSIVE=1
      shift
      ;;
    --overwrite)
      OVERWRITE=1
      shift
      ;;
    --no-keep-input-copy)
      KEEP_INPUT_COPY=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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

if [[ ! -d "$BASE_DIR" ]]; then
  printf 'Error: base directory does not exist: %s\n' "$BASE_DIR" >&2
  exit 2
fi

if [[ "$DRY_RUN" -eq 0 ]] && ! command -v "$PSI4_BIN" >/dev/null 2>&1; then
  printf 'Error: Psi4 executable not found: %s\n' "$PSI4_BIN" >&2
  exit 2
fi

collect_files() {
  local base="$1"
  if [[ "$RECURSIVE" -eq 1 ]]; then
    find "$base" -type f -name '*.dat' | sort
  else
    find "$base" -maxdepth 1 -type f -name '*.dat' | sort
  fi
}

printf 'status\tfile\tnote\n'

total=0
ran=0
skipped=0
failed=0

while IFS= read -r dat_file; do
  [[ -z "$dat_file" ]] && continue
  total=$((total + 1))

  if [[ "$OVERWRITE" -eq 0 ]] && grep -q '^ *Total Energy *=.*' "$dat_file"; then
    printf 'SKIP\t%s\talready contains Total Energy\n' "$dat_file"
    skipped=$((skipped + 1))
    continue
  fi

  input_copy="${dat_file}.input"
  if [[ "$KEEP_INPUT_COPY" -eq 1 ]] && [[ ! -f "$input_copy" ]]; then
    cp -- "$dat_file" "$input_copy"
  fi

  tmp_in="$(mktemp "${dat_file}.tmpin.XXXXXX")"
  cp -- "$dat_file" "$tmp_in"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'RUN\t%s\t%s "%s" "%s"\n' "$dat_file" "$PSI4_BIN" "$tmp_in" "$dat_file"
    rm -f -- "$tmp_in"
    ran=$((ran + 1))
    continue
  fi

  set +e
  "$PSI4_BIN" "$tmp_in" "$dat_file" >/dev/null 2>&1
  rc=$?
  set -e
  rm -f -- "$tmp_in"

  if [[ "$rc" -eq 0 ]]; then
    printf 'OK\t%s\tcompleted\n' "$dat_file"
    ran=$((ran + 1))
  else
    printf 'FAIL\t%s\tpsi4 exit code %d\n' "$dat_file" "$rc"
    failed=$((failed + 1))
  fi
done < <(collect_files "$BASE_DIR")

printf 'SUMMARY\t%s\ttotal=%d ran=%d skipped=%d failed=%d\n' "$BASE_DIR" "$total" "$ran" "$skipped" "$failed"

if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
