#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
required_submodules=(
  "third_party/openwire|crates/openwire/Cargo.toml"
)

canonical_path() {
  cd "$1" && pwd -P
}

for spec in "${required_submodules[@]}"; do
  path="${spec%%|*}"
  marker="${spec#*|}"
  full_path="${repo_root}/${path}"
  marker_path="${full_path}/${marker}"

  if [[ ! -f "${marker_path}" ]]; then
    echo "required submodule is not initialized: ${path}" >&2
    git -C "${repo_root}" -c submodule.recurse=false submodule update --init "${path}"
  fi

  if [[ ! -f "${marker_path}" ]]; then
    echo "required submodule is missing expected file: ${path}/${marker}" >&2
    exit 1
  fi

  submodule_root="$(git -C "${full_path}" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "${submodule_root}" || "$(canonical_path "${submodule_root}")" != "$(canonical_path "${full_path}")" ]]; then
    echo "required submodule is not checked out as its own worktree: ${path}" >&2
    exit 1
  fi

  if [[ -n "$(git -C "${full_path}" status --short --untracked-files=no)" ]]; then
    echo "required submodule has local modifications: ${path}" >&2
    git -C "${full_path}" status --short --untracked-files=no >&2
    exit 1
  fi
done

if [[ -n "$(git -C "${repo_root}" status --short --ignore-submodules=all -- third_party/openwire)" ]]; then
  echo "superproject has uncommitted submodule pointer changes" >&2
  git -C "${repo_root}" status --short --ignore-submodules=all -- third_party/openwire >&2
  exit 1
fi
