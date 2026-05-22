#!/usr/bin/env bash
# smoke-test.sh — Verify the built image has a working pi installation
set -uo pipefail

IMAGE="${1:?Usage: smoke-test.sh <image>}"

pass=0
fail=0

check() {
  local desc="$1" cmd="$2"
  printf "  %-45s " "$desc"
  if docker run --rm "$IMAGE" bash -lc "$cmd" >/dev/null 2>&1; then
    echo "✅ PASS"
    ((pass++)) || true
  else
    echo "❌ FAIL"
    ((fail++)) || true
  fi
}

echo "=== Smoke test for $IMAGE ==="

check "pi binary on PATH"          "command -v pi"
check "pi --version returns OK"    "pi --version"
check "fd binary on PATH"          "command -v fd"
check "version stamp file exists"  "[ -f \$HOME/.pi-image-version ]"

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
