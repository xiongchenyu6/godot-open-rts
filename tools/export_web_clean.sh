#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HIDDEN_ROOT="$(mktemp -d -t godot-open-rts-web-export-hidden.XXXXXX)"

restore_paths=()
export_log=""

cleanup_export() {
  for ((index=${#restore_paths[@]} - 1; index >= 0; index--)); do
    local rel_path="${restore_paths[index]}"
    local hidden_path="${HIDDEN_ROOT}/${rel_path}"
    local project_path="${PROJECT_ROOT}/${rel_path}"
    if [[ -e "${hidden_path}" ]]; then
      mkdir -p "$(dirname "${project_path}")"
      rm -rf "${project_path}"
      mv "${hidden_path}" "${project_path}"
    fi
  done
  rm -rf "${HIDDEN_ROOT}"
  if [[ -n "${export_log}" ]]; then
    rm -f "${export_log}"
  fi
}

hide_path_for_export() {
  local rel_path="$1"
  local project_path="${PROJECT_ROOT}/${rel_path}"
  local hidden_path="${HIDDEN_ROOT}/${rel_path}"
  if [[ ! -e "${project_path}" ]]; then
    return
  fi
  mkdir -p "$(dirname "${hidden_path}")"
  mv "${project_path}" "${hidden_path}"
  restore_paths+=("${rel_path}")
}

godot_template_version() {
  local raw_version
  raw_version="$(godot4 --headless --version)"
  if [[ "${raw_version}" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[[:alnum:]_+-]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return
  fi
  printf '%s\n' "${raw_version}"
}

ensure_text_server_data() {
  local template_root="${XDG_DATA_HOME:-${HOME}/.local/share}/godot/export_templates"
  local version
  version="$(godot_template_version)"
  local target_dir="${template_root}/${version}"
  local target_path="${target_dir}/icudt_godot.dat"

  if [[ -f "${target_path}" ]]; then
    return
  fi

  local candidate=""
  while IFS= read -r path; do
    candidate="${path}"
    break
  done < <(find "${template_root}" -maxdepth 2 -type f -name icudt_godot.dat 2>/dev/null | sort -Vr)

  if [[ -z "${candidate}" ]]; then
    echo "Missing Godot text server data: ${target_path}" >&2
    echo "Install the Godot ${version} export templates including icudt_godot.dat before publishing Web." >&2
    exit 1
  fi

  mkdir -p "${target_dir}"
  cp "${candidate}" "${target_path}"
  echo "Installed missing Godot text server data for ${version} from ${candidate}" >&2
}

trap cleanup_export EXIT

mkdir -p "${HIDDEN_ROOT}"

hide_path_for_export "assets/generated"
hide_path_for_export "assets/ui/icons/generated"
hide_path_for_export "source/match/debug"
hide_path_for_export "source/match/units/traits/debug"
hide_path_for_export "tests"
hide_path_for_export "tmp"

rm -f "${PROJECT_ROOT}/.godot/uid_cache.bin"
rm -f "${PROJECT_ROOT}/.godot/global_script_class_cache.cfg"

cd "${PROJECT_ROOT}"
ensure_text_server_data

export_log="$(mktemp)"
set +e
godot4 --headless --export-release "Web" "docs/index.html" 2>&1 | tee "${export_log}"
export_status=${PIPESTATUS[0]}
set -e

if (( export_status != 0 )); then
  exit "${export_status}"
fi

if grep -F -q "Missing text server data" "${export_log}"; then
  echo "Web export is missing text server data; Chinese/localized text may render incorrectly." >&2
  exit 1
fi
