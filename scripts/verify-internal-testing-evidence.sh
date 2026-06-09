#!/usr/bin/env bash
set -euo pipefail

evidence_file="${1:-docs/release/internal-testing-evidence.md}"

if [[ ! -f "$evidence_file" ]]; then
  echo "internal testing evidence file not found: $evidence_file" >&2
  exit 2
fi

awk -F'|' '
BEGIN {
  required["iOS" SUBSEP "App Store Connect record"] = 1
  required["Android" SUBSEP "Play Console record"] = 1
  required["iOS" SUBSEP "Internal testing build"] = 1
  required["Android" SUBSEP "Internal testing build"] = 1
  required["iOS" SUBSEP "Tester invites"] = 1
  required["Android" SUBSEP "Tester invites"] = 1
  required["iOS" SUBSEP "Feedback triage"] = 1
  required["Android" SUBSEP "Feedback triage"] = 1

  allowed_status["Complete"] = 1
  allowed_status["Accepted"] = 1

  row_count = 0
  failure_count = 0
  in_required_evidence = 0
}

function trim(value) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
  return value
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
  if (tolower(value) == "complete") {
    return "Complete"
  }
  if (tolower(value) == "accepted") {
    return "Accepted"
  }
  return value
}

function fail(row_label, message) {
  failure_count += 1
  printf("FAIL: %s: %s\n", row_label, message) > "/dev/stderr"
}

function contains_fake_evidence_marker(value, normalized) {
  normalized = tolower(value)
  return normalized ~ /(^|[^[:alnum:]])(fake|mock|placeholder|dummy|synthetic)([^[:alnum:]]|$)/ ||
    normalized ~ /(^|[^[:alnum:]])(todo|tbd)([^[:alnum:]]|$)/ ||
    normalized ~ /example[.]com|not[- ]real/
}

function is_template_row(date, platform, gate, owner, status, link, notes) {
  return date == "" && platform == "" && gate == "" && owner == "" && status == "" && link == "" && notes == ""
}

/^## Required Evidence[[:space:]]*$/ {
  in_required_evidence = 1
  next
}

in_required_evidence && /^## / {
  in_required_evidence = 0
  next
}

in_required_evidence && /^\|/ {
  if ($2 ~ /^[[:space:]]*Date[[:space:]]*$/ || $2 ~ /^[[:space:]]*---[[:space:]]*$/) {
    next
  }

  date = trim($2)
  platform = normalize_platform($3)
  gate = trim($4)
  owner = trim($5)
  status = normalize_status($6)
  link = trim($7)
  notes = trim($8)
  row_label = platform " " gate

  if (is_template_row(date, platform, gate, owner, status, link, notes)) {
    next
  }

  row_count += 1

  if (date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
    fail(row_label, "date must use YYYY-MM-DD")
  }

  if (!(platform == "iOS" || platform == "Android")) {
    fail(row_label, "platform must be iOS or Android")
  }

  if (!((platform SUBSEP gate) in required)) {
    fail(row_label, "gate is not one of the required platform/gate pairs")
  }

  if (owner == "") {
    fail(row_label, "owner is required")
  }

  if (!(status in allowed_status)) {
    fail(row_label, "status must be Complete or Accepted, found " status)
  }

  if (link == "") {
    fail(row_label, "evidence link is required")
  }

  if (notes == "") {
    fail(row_label, "notes are required")
  }

  if ((status in allowed_status) && contains_fake_evidence_marker(link " " notes)) {
    fail(row_label, "evidence link/notes must not contain fake, mock, placeholder, dummy, synthetic, TODO, TBD, example.com, not-real, or not real markers")
  }

  if (status == "Accepted" && notes !~ /[Aa]pprov|[Ww]aiv|[Aa]ccept/) {
    fail(row_label, "accepted rows require approver and reason in notes")
  }

  if (gate == "Internal testing build") {
    if (notes !~ /[Bb]uild/) {
      fail(row_label, "internal testing build notes must include build number")
    }
    if (notes !~ /[Cc]ommit|[Ss][Hh][Aa]/) {
      fail(row_label, "internal testing build notes must include commit SHA")
    }
  }

  if (gate == "Tester invites") {
    if (notes !~ /[Gg]roup|[Ll]ist/) {
      fail(row_label, "tester invite notes must include group or list name")
    }
    if (notes !~ /[Ii]nvit/) {
      fail(row_label, "tester invite notes must include invite date/status")
    }
  }

  if (gate == "Feedback triage") {
    if (notes !~ /[Bb]locker/) {
      fail(row_label, "feedback triage notes must summarize blocker count")
    }
    if (notes !~ /[Rr]isk|[Aa]ccept/) {
      fail(row_label, "feedback triage notes must summarize accepted risks")
    }
  }

  seen[platform SUBSEP gate] = 1
}

END {
  for (key in required) {
    split(key, parts, SUBSEP)
    platform = parts[1]
    gate = parts[2]
    if (!(platform SUBSEP gate in seen)) {
      fail(platform " " gate, "missing required internal testing evidence row")
    }
  }

  if (row_count == 0) {
    fail("Required Evidence", "no internal testing evidence rows found")
  }

  if (failure_count > 0) {
    printf("Internal testing evidence verification failed: %d row(s), %d failure(s)\n", row_count, failure_count) > "/dev/stderr"
    exit 1
  }

  printf("Internal testing evidence verification passed: %d row(s)\n", row_count)
}
' "$evidence_file"
