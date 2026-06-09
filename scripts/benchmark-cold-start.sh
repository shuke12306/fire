#!/usr/bin/env bash
set -euo pipefail

platform="${1:-android}"
iterations="${ITERATIONS:-5}"

case "$platform" in
  android)
    command -v adb >/dev/null 2>&1 || {
      echo "adb is required for Android cold-start measurement" >&2
      exit 2
    }
    package="${ANDROID_PACKAGE:-com.fire.app}"
    activity="${ANDROID_ACTIVITY:-.MainActivity}"
    total=0
    echo "# Android cold-start benchmark"
    for run in $(seq 1 "$iterations"); do
      adb shell am force-stop "$package" >/dev/null
      sleep 1
      output="$(adb shell am start -W -n "$package/$activity")"
      elapsed="$(printf '%s\n' "$output" | awk -F: '/TotalTime/ { gsub(/ /, "", $2); print $2 }')"
      if [[ -z "$elapsed" ]]; then
        echo "Could not parse TotalTime from adb output:" >&2
        printf '%s\n' "$output" >&2
        exit 1
      fi
      total=$((total + elapsed))
      echo "run $run: ${elapsed}ms"
    done
    average=$((total / iterations))
    echo "average: ${average}ms"
    (( average <= 5000 )) || exit 1
    ;;
  ios)
    cat <<'EOF'
# iOS cold-start benchmark

Use Instruments or xctrace on a release build:

1. Build/archive Fire for a physical device.
2. Kill Fire.
3. Record launch with Time Profiler or App Launch template.
4. Measure launch start to first home topic row visible.
5. Record the result in docs/release/performance-benchmarks.md.

Target: < 3000ms. Failure threshold: > 5000ms.
EOF
    ;;
  *)
    echo "usage: scripts/benchmark-cold-start.sh [android|ios]" >&2
    exit 2
    ;;
esac
