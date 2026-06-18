#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot4}"
TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-120}"
SHOWCASE_TIMEOUT_SECONDS="${SHOWCASE_TIMEOUT_SECONDS:-40}"
SHOWCASE_QUIT_AFTER_SECONDS="${SHOWCASE_QUIT_AFTER_SECONDS:-8}"
LOG_DIR="${LOG_DIR:-/tmp/godot-open-rts-release-smoke}"
CRITICAL_LOG_PATTERN="${CRITICAL_LOG_PATTERN:-SCRIPT ERROR|Parse Error|Invalid call|Invalid access|push_error}"

release_tests=(
  TestReleaseFeatureFlags
  TestLocalization
  TestMainMenu
  TestPlayMenu
  TestSkirmishMaps
  TestUnitRegistry
  TestHudCommandPanel
  TestCommandIconRender
  TestActionTargetLoss
  TestResourcesBarPower
  TestProductionQueueHud
  TestBattleNotifications
  TestCameraEdgeMovement
  TestUnitVoices
  TestRuntimePlayerSwitch
  TestMatchStartIdle
  TestMatchEndChineseVictory
  TestMatchEndVictory
  TestMatchEndDefeat
  TestAIMixedOffenseProduction
  TestAISupportPowers
  TestPlayerColors
)

showcase_scenes=(
  TestAllUnits
  TestNonQuadraticMap
  TestOneUnit
  TestPlayerVsAI
  TestUnitsFightingEachOther
)

VALIDATE_MANUAL_TESTS_ONLY=1 bash tools/run_manual_tests.sh

mkdir -p "${LOG_DIR}"
for test_name in "${release_tests[@]}"; do
  log_path="${LOG_DIR}/${test_name}.log"
  printf '\n== release smoke: %s ==\n' "${test_name}"
  set +e
  timeout "${TEST_TIMEOUT_SECONDS}s" "${GODOT_BIN}" --headless --path . \
    "tests/manual/${test_name}.tscn" >"${log_path}" 2>&1
  test_status="$?"
  set -e
  if [[ "${test_status}" -ne 0 ]]; then
    printf 'Release smoke failed: %s (exit %s)\n' "${test_name}" "${test_status}" >&2
    cat "${log_path}" >&2
    exit "${test_status}"
  fi
  if rg -n "${CRITICAL_LOG_PATTERN}" "${log_path}" >/tmp/release-smoke-critical-match.txt; then
    printf 'Release smoke emitted critical errors: %s\n' "${test_name}" >&2
    cat /tmp/release-smoke-critical-match.txt >&2
    cat "${log_path}" >&2
    exit 1
  fi
done

for scene_name in "${showcase_scenes[@]}"; do
  log_path="${LOG_DIR}/${scene_name}.log"
  printf '\n== release showcase: %s ==\n' "${scene_name}"
  set +e
  timeout "${SHOWCASE_TIMEOUT_SECONDS}s" "${GODOT_BIN}" --headless --path . \
    "tests/manual/${scene_name}.tscn" --quit-after "${SHOWCASE_QUIT_AFTER_SECONDS}" \
    >"${log_path}" 2>&1
  test_status="$?"
  set -e
  if [[ "${test_status}" -ne 0 ]]; then
    printf 'Release showcase failed: %s (exit %s)\n' "${scene_name}" "${test_status}" >&2
    cat "${log_path}" >&2
    exit "${test_status}"
  fi
  if rg -n "${CRITICAL_LOG_PATTERN}" "${log_path}"; then
    cat "${log_path}"
    exit 1
  fi
done

printf '\nRelease smoke passed: %s automated scenes, %s showcase scenes (logs: %s)\n' \
  "${#release_tests[@]}" "${#showcase_scenes[@]}" "${LOG_DIR}"
