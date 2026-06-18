#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot4}"
TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-90}"
LOG_DIR="${LOG_DIR:-/tmp/godot-open-rts-manual-tests}"
VERBOSE_TEST_LOGS="${VERBOSE_TEST_LOGS:-0}"
CRITICAL_LOG_PATTERN="${CRITICAL_LOG_PATTERN:-SCRIPT ERROR|Parse Error|Invalid call|Invalid access|push_error}"

tests=(
  TestAIBattlegroupActionMonitor
  TestAIBattlegroupDeployMode
  TestAIBattlegroupRepairSupport
  TestAIConstructionAssignment
  TestAIDefensePlacement
  TestAIDifficulty
  TestAIEconomyHarvesters
  TestAIEconomyOrePurifier
  TestAIEngineerCapture
  TestAIMixedOffenseProduction
  TestAIOffensePlacement
  TestAIResourceRequestReentrancy
  TestAISaboteurInfiltration
  TestAISupplyCrateCollection
  TestAISupportPowers
  TestAITechBunkerGarrison
  TestActionTargetLoss
  TestAdvancedAircraftProduction
  TestAdvancedDefenseConstruction
  TestAdvancedPowerConstruction
  TestAdvancedVehicleProduction
  TestAirToTerrainMarker
  TestAlliances
  TestArmySelectionHotkeys
  TestAttackMove
  TestBarracksProduction
  TestBattleEventFocus
  TestBattleNotifications
  TestCameraEdgeMovement
  TestCameraBookmarks
  TestCancelCurrentActionHotkey
  TestCombatWreckage
  TestCommandHotkeys
  TestCommandIconRender
  TestDroneMineLayer
  TestEngineerCapture
  TestEngineerRepair
  TestForceMoveCommand
  TestFourCornersMatch
  TestHoldPosition
  TestHudCommandPanel
  TestLowPowerDefense
  TestLowPowerProduction
  TestLocalization
  TestMainMenu
  TestMatchBriefing
  TestMatchEndChineseVictory
  TestMatchEndDefeat
  TestMatchEndVictory
  TestMatchMenu
  TestMatchRestart
  TestMatchStartIdle
  TestMobileConstructionVehicle
  TestMobileShieldProjector
  TestOrePurifierEconomy
  TestPatrolCommand
  TestPlayMenu
  TestPlayerColors
  TestProductionQueueHud
  TestProductionStructureHotkeys
  TestQueuedTerrainCommands
  TestRadarMinimap
  TestRallyPointCommand
  TestRefineryDropoff
  TestRefineryHarvesterSpawn
  TestReleaseFeatureFlags
  TestRepairPadConstruction
  TestResourcesBarPower
  TestRuntimePlayerSwitch
  TestSaboteurInfiltration
  TestSaboteurPowerSabotage
  TestSaboteurProductionVeterancy
  TestScatterCommand
  TestSelectionInfo
  TestSiegeDrillDeployMode
  TestSkirmishMaps
  TestSplashDamage
  TestStructureSelling
  TestSupplyCrate
  TestSupportPowers
  TestTechBunkerGarrison
  TestTechHospital
  TestTechOilDerrick
  TestTechRepairDepot
  TestTeslaFenceSegment
  TestUnitGroups
  TestUnitRegistry
  TestUnitVoices
  TestUtilsRouletteWheel
  TestVehicleCrushing
  TestVeterancy
)

manual_only_tests=(
  TestAllUnits
  TestNonQuadraticMap
  TestOneUnit
  TestPlayerVsAI
  TestUnitsFightingEachOther
)

normalize_test_name() {
  local test_name="$1"
  test_name="${test_name#"${test_name%%[![:space:]]*}"}"
  test_name="${test_name%"${test_name##*[![:space:]]}"}"
  test_name="${test_name##*/}"
  test_name="${test_name%.tscn}"
  printf '%s' "${test_name}"
}

requested_tests=()
if [[ "$#" -gt 0 ]]; then
  requested_tests=("$@")
elif [[ -n "${TEST_SCENES:-}" ]]; then
  IFS=',' read -r -a requested_tests <<<"${TEST_SCENES}"
elif [[ -n "${TESTS:-}" ]]; then
  IFS=',' read -r -a requested_tests <<<"${TESTS}"
fi

missing_tests="$(
  comm -23 \
    <(find tests/manual -maxdepth 1 -name 'Test*.tscn' -printf '%f\n' | sed 's/\.tscn$//' | sort) \
    <(printf '%s\n' "${tests[@]}" "${manual_only_tests[@]}" | sort)
)"
if [[ -n "${missing_tests}" ]]; then
  printf 'Unclassified manual tests found:\n%s\n' "${missing_tests}" >&2
  printf 'Add automated tests to tests=(), or non-quitting showcase scenes to manual_only_tests=().\n' >&2
  exit 1
fi

if [[ "${VALIDATE_MANUAL_TESTS_ONLY:-0}" == "1" ]]; then
  exit 0
fi

selected_tests=("${tests[@]}")
if [[ "${#requested_tests[@]}" -gt 0 ]]; then
  declare -A automated_test_names=()
  declare -A manual_only_test_names=()
  for test_name in "${tests[@]}"; do
    automated_test_names["${test_name}"]=1
  done
  for test_name in "${manual_only_tests[@]}"; do
    manual_only_test_names["${test_name}"]=1
  done

  selected_tests=()
  for requested_test_name in "${requested_tests[@]}"; do
    test_name="$(normalize_test_name "${requested_test_name}")"
    if [[ -z "${test_name}" ]]; then
      continue
    fi
    if [[ -n "${automated_test_names[${test_name}]:-}" ]]; then
      selected_tests+=("${test_name}")
    elif [[ -n "${manual_only_test_names[${test_name}]:-}" ]]; then
      printf 'Manual-only scene cannot be run by this automated test script: %s\n' "${test_name}" >&2
      printf 'Use tools/run_release_smoke.sh or run it with --quit-after manually.\n' >&2
      exit 1
    else
      printf 'Unknown automated manual test: %s\n' "${test_name}" >&2
      printf 'Known automated tests:\n%s\n' "$(printf '  %s\n' "${tests[@]}")" >&2
      exit 1
    fi
  done
fi

if [[ "${#selected_tests[@]}" -eq 0 ]]; then
  printf 'No automated manual tests selected.\n' >&2
  exit 1
fi

for test_name in "${selected_tests[@]}"; do
  printf '\n== %s ==\n' "${test_name}"
  mkdir -p "${LOG_DIR}"
  log_path="${LOG_DIR}/${test_name}.log"
  set +e
  if [[ "${VERBOSE_TEST_LOGS}" == "1" ]]; then
    timeout "${TEST_TIMEOUT_SECONDS}s" "${GODOT_BIN}" --headless --path . \
      "tests/manual/${test_name}.tscn" 2>&1 | tee "${log_path}"
    test_status="${PIPESTATUS[0]}"
  else
    timeout "${TEST_TIMEOUT_SECONDS}s" "${GODOT_BIN}" --headless --path . \
      "tests/manual/${test_name}.tscn" >"${log_path}" 2>&1
    test_status="$?"
  fi
  set -e
  if [[ "${test_status}" -ne 0 ]]; then
    printf 'Manual test failed: %s (exit %s)\n' "${test_name}" "${test_status}" >&2
    cat "${log_path}" >&2
    exit "${test_status}"
  fi
  if rg -n "${CRITICAL_LOG_PATTERN}" "${log_path}" >/tmp/manual-test-critical-match.txt; then
    printf 'Manual test emitted critical errors: %s\n' "${test_name}" >&2
    cat /tmp/manual-test-critical-match.txt >&2
    cat "${log_path}" >&2
    exit 1
  fi
done

if [[ "${#requested_tests[@]}" -gt 0 ]]; then
  printf '\nSelected manual regression tests passed: %s (logs: %s)\n' \
    "${#selected_tests[@]}" "${LOG_DIR}"
else
  printf '\nManual regression tests passed: %s (logs: %s)\n' "${#selected_tests[@]}" "${LOG_DIR}"
fi
