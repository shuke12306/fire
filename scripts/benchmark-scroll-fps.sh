#!/usr/bin/env bash
set -euo pipefail

platform="${1:-android}"

case "$platform" in
  android)
    command -v adb >/dev/null 2>&1 || {
      echo "adb is required for Android scroll measurement" >&2
      exit 2
    }
    package="${ANDROID_PACKAGE:-com.fire.app}"
    echo "# Android scroll benchmark"
    echo "Resetting gfxinfo for $package"
    adb shell dumpsys gfxinfo "$package" reset >/dev/null || true
    echo "Scroll the home feed for 10 seconds."
    sleep 10
    adb shell dumpsys gfxinfo "$package" | awk '
      /Total frames rendered/ || /Janky frames/ || /50th percentile/ || /90th percentile/ || /95th percentile/ || /99th percentile/ { print }
    '
    ;;
  ios)
    cat <<'EOF'
# iOS scroll benchmark

Use Instruments Core Animation or xctrace on a release build:

1. Open Fire to the home feed.
2. Start an animation/FPS trace.
3. Scroll continuously for 10 seconds.
4. Record average FPS and hitch count in docs/release/performance-benchmarks.md.

Target: >= 58 fps average. Failure threshold: < 55 fps average.
EOF
    ;;
  *)
    echo "usage: scripts/benchmark-scroll-fps.sh [android|ios]" >&2
    exit 2
    ;;
esac
