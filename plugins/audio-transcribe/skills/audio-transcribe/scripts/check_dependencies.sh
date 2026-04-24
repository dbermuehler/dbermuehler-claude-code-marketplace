#!/usr/bin/env bash
# Verify that required tools are available.
# Prints ERROR and exits 1 if something is missing.

missing=()

if ! command -v uv &>/dev/null; then
  missing+=("uv (https://docs.astral.sh/uv/)")
fi

if [ ${#missing[@]} -ne 0 ]; then
  echo "ERROR: Missing required dependencies:"
  for dep in "${missing[@]}"; do
    echo "  - $dep"
  done
  exit 1
fi

echo "OK"
