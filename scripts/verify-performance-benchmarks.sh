#!/usr/bin/env bash
set -euo pipefail

benchmark_file="${1:-docs/release/performance-benchmarks.md}"

if [[ ! -f "$benchmark_file" ]]; then
  echo "performance benchmark file not found: $benchmark_file" >&2
  exit 2
fi

awk -F'|' '
BEGIN {
  required_metric["Cold start to home visible"] = 1
  required_metric["Home feed scroll fluency"] = 1
  required_metric["Topic detail first screen"] = 1
  required_metric["Home feed memory"] = 1
  required_metric["Topic detail memory after 100 posts"] = 1

  required_platform["iOS"] = 1
  required_platform["Android"] = 1

  row_count = 0
  failure_count = 0
  in_results_log = 0
}

function trim(value) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
  return value
}

function fail(row_label, message) {
  failure_count += 1
  printf("FAIL: %s: %s\n", row_label, message) > "/dev/stderr"
}

function normalize_platform(value) {
  value = trim(value)
  if (tolower(value) == "ios") {
    return "iOS"
  }
  if (tolower(value) == "android") {
    return "Android"
  }
  return value
}

function normalize_status(value) {
  value = trim(value)
  if (tolower(value) == "pass") {
    return "Pass"
  }
  if (tolower(value) == "accepted") {
    return "Accepted"
  }
  if (tolower(value) == "fail") {
    return "Fail"
  }
  return value
}

function is_template_row(date, commit, platform, device, build_type, metric, result, status, notes) {
  return date == "" && commit == "" && platform == "" && device == "" && build_type == "" && metric == "" && result == "" && status == "" && notes == ""
}

/^## Results Log[[:space:]]*$/ {
  in_results_log = 1
  next
}

in_results_log && /^## / {
  in_results_log = 0
  next
}

in_results_log && /^\|/ {
  if ($2 ~ /^[[:space:]]*Date[[:space:]]*$/ || $2 ~ /^[[:space:]]*---[[:space:]]*$/) {
    next
  }

  date = trim($2)
  commit = trim($3)
  platform = normalize_platform($4)
  device = trim($5)
  build_type = trim($6)
  metric = trim($7)
  result = trim($8)
  status = normalize_status($9)
  notes = trim($10)
  row_label = platform " " metric

  if (is_template_row(date, commit, platform, device, build_type, metric, result, status, notes)) {
    next
  }

  row_count += 1

  if (date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
    fail(row_label, "date must use YYYY-MM-DD")
  }

  if (commit !~ /^[0-9a-fA-F]{7,40}$/) {
    fail(row_label, "commit must be a 7-40 character git SHA")
  }

  if (!(platform in required_platform)) {
    fail(row_label, "platform must be iOS or Android")
  }

  if (device == "") {
    fail(row_label, "physical device name is required")
  }

  if (device ~ /[Ss]imulator|[Ee]mulator/) {
    fail(row_label, "release benchmark evidence must use a physical device")
  }

  if (tolower(build_type) !~ /^release/) {
    fail(row_label, "build type must be a release build")
  }

  if (!(metric in required_metric)) {
    fail(row_label, "metric must match one of the documented target names")
  }

  if (result == "") {
    fail(row_label, "result is required")
  }

  if (status == "Fail") {
    fail(row_label, "failing threshold results must be fixed or explicitly Accepted")
  } else if (status != "Pass" && status != "Accepted") {
    fail(row_label, "status must be Pass or Accepted, found " status)
  }

  if (status == "Accepted" && notes == "") {
    fail(row_label, "accepted threshold waivers require notes")
  }

  seen[platform SUBSEP metric] = 1
}

END {
  for (platform in required_platform) {
    for (metric in required_metric) {
      if (!(platform SUBSEP metric in seen)) {
        fail(platform " " metric, "missing release-build physical-device result")
      }
    }
  }

  if (row_count == 0) {
    fail("Results Log", "no performance benchmark result rows found")
  }

  if (failure_count > 0) {
    printf("Performance benchmark verification failed: %d row(s), %d failure(s)\n", row_count, failure_count) > "/dev/stderr"
    exit 1
  }

  printf("Performance benchmark verification passed: %d row(s)\n", row_count)
}
' "$benchmark_file"
