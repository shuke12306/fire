#!/usr/bin/env bash
set -euo pipefail

platform="${1:-android}"

case "$platform" in
  android)
    command -v adb >/dev/null 2>&1 || {
      echo "adb is required for Android topic-load measurement" >&2
      exit 2
    }
    package="${ANDROID_PACKAGE:-com.fire.app}"
    echo "# Android topic-load benchmark"
    echo "This script captures logcat while you open a topic. Timing markers must be present in the build logs."
    adb shell logcat -c
    echo "Open a home-feed topic now. Waiting up to 20 seconds for topic detail timing logs..."
    timeout 20 adb shell logcat -v time | grep -E "TopicDetail|topic detail|first.*post|first.*screen" || {
      echo "No topic-detail timing markers captured. Record manually and update docs/release/performance-benchmarks.md." >&2
      exit 1
    }
    ;;
  ios)
    cat <<'EOF'
# iOS topic-load benchmark

Use Instruments signposts or Time Profiler on a release build:

1. Open Fire to home feed.
2. Start recording.
3. Tap a topic.
4. Measure tap to first post row visible.
5. Record the result in docs/release/performance-benchmarks.md.

Target: < 2000ms. Failure threshold: > 3000ms.
EOF
    ;;
  *)
    echo "usage: scripts/benchmark-topic-load.sh [android|ios]" >&2
    exit 2
    ;;
esac
