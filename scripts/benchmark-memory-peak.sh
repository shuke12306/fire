#!/usr/bin/env bash
set -euo pipefail

platform="${1:-android}"

case "$platform" in
  android)
    command -v adb >/dev/null 2>&1 || {
      echo "adb is required for Android memory measurement" >&2
      exit 2
    }
    package="${ANDROID_PACKAGE:-com.fire.app}"
    echo "# Android memory benchmark"
    adb shell dumpsys meminfo "$package" | awk '
      NR <= 20 { print }
      /TOTAL/ { print }
    '
    ;;
  ios)
    cat <<'EOF'
# iOS memory benchmark

Use Instruments Allocations on a release build:

1. Launch Fire under Allocations.
2. Measure home feed after initial content load.
3. Open a topic with at least 100 posts and scroll through it.
4. Record peak memory in docs/release/performance-benchmarks.md.

Targets: < 200 MB home, < 350 MB topic detail.
EOF
    ;;
  *)
    echo "usage: scripts/benchmark-memory-peak.sh [android|ios]" >&2
    exit 2
    ;;
esac
