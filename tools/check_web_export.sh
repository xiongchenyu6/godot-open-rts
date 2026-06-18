#!/usr/bin/env bash
set -euo pipefail

DOCS_DIR="${DOCS_DIR:-docs}"
PCK_PATH="${DOCS_DIR}/index.pck"
HTML_PATH="${DOCS_DIR}/index.html"
WASM_PATH="${DOCS_DIR}/index.wasm"
MAX_PCK_BYTES="${WEB_PCK_MAX_BYTES:-100000000}"

assert_no_runtime_references_to_web_excluded_paths() {
  local matches

  matches="$(
    rg -n \
      --glob '!source/match/debug/**' \
      --glob '!source/match/units/traits/debug/**' \
      --glob '!tests/**' \
      --glob '!tmp/**' \
      --glob '!assets/generated/**' \
      --glob '!assets/ui/icons/generated/**' \
      'res://(source/match/debug|source/match/units/traits/debug|tests|assets/generated|assets/ui/icons/generated)/' \
      source project.godot 2>/dev/null || true
  )"

  if [[ -n "${matches}" ]]; then
    echo "Runtime source references resources that the Web export excludes:" >&2
    echo "${matches}" >&2
    echo "Move the code/resource out of the excluded path, or create Web-safe runtime code instead of preloading excluded files." >&2
    exit 1
  fi

  matches="$(
    rg -n \
      --glob '!tests/**' \
      '(preload|load)\("res://tmp/|path="res://tmp/' \
      source project.godot 2>/dev/null || true
  )"

  if [[ -n "${matches}" ]]; then
    echo "Runtime source statically loads resources from res://tmp/, which the Web export excludes:" >&2
    echo "${matches}" >&2
    echo "Use user:// for runtime state, or keep tmp-only paths behind non-static feature flags." >&2
    exit 1
  fi
}

assert_no_runtime_references_to_web_excluded_paths

for path in "${HTML_PATH}" "${PCK_PATH}" "${WASM_PATH}"; do
  if [[ ! -f "${path}" ]]; then
    echo "Missing web export artifact: ${path}" >&2
    exit 1
  fi
done

pck_size="$(stat -c '%s' "${PCK_PATH}")"
if (( pck_size > MAX_PCK_BYTES )); then
  echo "Web export PCK is too large: ${pck_size} bytes > ${MAX_PCK_BYTES} bytes" >&2
  echo "Check export_presets.cfg before publishing; resource exclude mode can pack non-resource files." >&2
  exit 1
fi

if command -v strings >/dev/null 2>&1; then
  pck_strings="$(mktemp)"
  trap 'rm -f "${pck_strings}"' EXIT
  strings "${PCK_PATH}" >"${pck_strings}"

  assert_pck_excludes_entry_prefix() {
    local label="$1"
    local resource_prefix="$2"

    if rg -F -q "${resource_prefix}" "${pck_strings}"; then
      echo "Web export still contains ${label}: ${resource_prefix}" >&2
      echo "Check export_presets.cfg and run tools/export_web_clean.sh before publishing." >&2
      exit 1
    fi
  }

  assert_referenced_runtime_assets_packaged() {
    local label="$1"
    local resource_pattern="$2"
    shift 2

    while IFS= read -r resource_path; do
      local resource_entry="${resource_path#res://}"
      if [[ ! -f "${resource_entry}" ]]; then
        echo "Source references missing ${label}: ${resource_path}" >&2
        exit 1
      fi
      if ! rg -F -q "${resource_entry}" "${pck_strings}"; then
        echo "Web export is missing referenced ${label}: ${resource_entry}" >&2
        exit 1
      fi
    done < <(rg --no-filename -o "${resource_pattern}" "$@" | sort -u)
  }

  required_entries=(
    "icudt_godot.dat"
    "source/match/hud/RtsHudStyler.gdc"
    "source/match/hud/unit-menus/CommandButtonIcons.gdc"
    "source/match/hud/unit-menus/CommandIconOverlay.gdc"
  )
  for entry in "${required_entries[@]}"; do
    if ! rg -F -q "${entry}" "${pck_strings}"; then
      echo "Web export is missing required runtime entry: ${entry}" >&2
      exit 1
    fi
  done

  assert_referenced_runtime_assets_packaged \
    "UI icon" \
    'res://assets/ui/icons/[A-Za-z0-9_/-]+\.png' \
    source
  assert_referenced_runtime_assets_packaged \
    "audio/voice/music asset" \
    'res://assets/(sfx|voice|music)/[A-Za-z0-9_./ -]+\.(wav|ogg)' \
    source
  assert_referenced_runtime_assets_packaged \
    "translation asset" \
    'res://assets/translations/[A-Za-z0-9_./ -]+\.translation' \
    project.godot

  assert_pck_excludes_entry_prefix "generated asset resources" "res://assets/generated/"
  assert_pck_excludes_entry_prefix "generated UI icon resources" "res://assets/ui/icons/generated/"
  assert_pck_excludes_entry_prefix "temporary project files" "res://tmp/"
  assert_pck_excludes_entry_prefix "debug match resources" "res://source/match/debug/"
  assert_pck_excludes_entry_prefix "debug unit trait resources" "res://source/match/units/traits/debug/"
  assert_pck_excludes_entry_prefix "test resources" "res://tests/"
  assert_pck_excludes_entry_prefix "Godot uid cache" "res://.godot/uid_cache.bin"
  assert_pck_excludes_entry_prefix "Godot global script cache" "res://.godot/global_script_class_cache.cfg"
fi

echo "Web export OK: ${PCK_PATH} (${pck_size} bytes)"
