#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "# Third-Party Licenses"
echo
echo "Generated on: $(date -u +%Y-%m-%d)"
echo
echo "This inventory is generated from dependency declarations and lockfiles. It is a release-review input, not legal advice."
echo

echo "## Rust Workspace"
echo
if command -v cargo-license >/dev/null 2>&1; then
  cargo license --manifest-path Cargo.toml
else
  echo "cargo-license is not installed."
  echo
  echo "Install and regenerate:"
  echo
  echo '```bash'
  echo "cargo install cargo-license"
  echo "scripts/collect-licenses.sh > docs/release/third-party-licenses.md"
  echo '```'
  echo
  echo "Workspace crates declared in Cargo.lock:"
  awk '
    /^name = / { name=$3; gsub(/"/, "", name) }
    /^version = / && name != "" { version=$3; gsub(/"/, "", version); print "- " name " " version; name="" }
  ' Cargo.lock | sort -u
fi

echo
echo "## iOS Swift Packages"
echo
ios_package_file="native/ios-app/Fire.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [[ -f "$ios_package_file" ]]; then
  python3 - "$ios_package_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

pins = data.get("pins") or data.get("object", {}).get("pins", [])
for pin in sorted(pins, key=lambda item: item.get("identity", item.get("package", ""))):
    identity = pin.get("identity") or pin.get("package") or "unknown"
    location = pin.get("location") or pin.get("repositoryURL") or ""
    state = pin.get("state", {})
    version = state.get("version") or state.get("revision") or ""
    suffix = f" ({version})" if version else ""
    print(f"- {identity}{suffix}: {location}")
PY
else
  echo "No Swift Package.resolved file found at $ios_package_file."
fi

echo
echo "## iOS Vendored Local Packages"
echo
if [[ -f native/ios-app/LocalPackages/TextureCore/LICENSE-Texture-3.2.0.txt ]]; then
  echo "- Texture 3.2.0: native/ios-app/LocalPackages/TextureCore/LICENSE-Texture-3.2.0.txt"
else
  echo "No vendored iOS license files found."
fi

echo
echo "## Android Gradle Dependencies"
echo
if [[ -f native/android-app/build.gradle.kts ]]; then
  python3 - <<'PY'
import re
from pathlib import Path

text = Path("native/android-app/build.gradle.kts").read_text(encoding="utf-8")
pattern = re.compile(r'(?:implementation|testImplementation)\((?:platform\()?\"([^\"]+)\"')
for dependency in sorted(set(pattern.findall(text))):
    print(f"- {dependency}")
PY
else
  echo "No Android build.gradle.kts found."
fi

echo
echo "## Repository Licenses"
echo
for file in LICENSE third_party/openwire/LICENSE; do
  if [[ -f "$file" ]]; then
    echo "- $file"
  fi
done

echo
echo "## Release Review Notes"
echo
echo "- Verify transitive Android licenses with Gradle dependency tooling before submission."
echo "- Verify Swift package license texts before submission."
echo "- Do not include read-only reference-project dependencies from references/fluxdo in Fire's shipped license list unless they are actually shipped."
