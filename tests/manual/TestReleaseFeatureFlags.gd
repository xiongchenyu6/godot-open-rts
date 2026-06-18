extends Node

const DiagnosticHudScene = preload("res://source/match/debug/DiagnosticHud.tscn")
const FrameIncrementerScene = preload("res://source/match/debug/FrameIncrementer.tscn")
const GodModeHudScene = preload("res://source/match/debug/GodModeHud.tscn")
const MatchScene = preload("res://source/match/Match.tscn")

const RELEASE_BLOCKED_MATCH_NODES = [
	"Debug",
	"DiagnosticHUD",
	"FrameIncrementer",
	"GodModeHUD",
]


func _ready():
	assert(not FeatureFlags.god_mode, "release defaults should disable god mode")
	assert(not FeatureFlags.frame_incrementer, "release defaults should disable frame incrementer")
	assert(not FeatureFlags.diagnostic_hud, "release defaults should disable diagnostic HUD")

	Globals.god_mode = false
	Globals._toggle_god_mode()
	assert(not Globals.god_mode, "god mode toggle should be ignored when release flag is disabled")

	await _assert_debug_scene_frees_itself(DiagnosticHudScene, "diagnostic HUD")
	await _assert_debug_scene_frees_itself(FrameIncrementerScene, "frame incrementer")
	await _assert_debug_scene_frees_itself(GodModeHudScene, "god mode HUD")
	_assert_match_scene_excludes_debug_nodes()

	get_tree().quit()


func _assert_debug_scene_frees_itself(scene, label):
	var node = scene.instantiate()
	var node_ref = weakref(node)
	add_child(node)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(node_ref.get_ref() == null, "{0} should not remain active in release defaults".format([label]))


func _assert_match_scene_excludes_debug_nodes():
	var state = MatchScene.get_state()
	for index in range(state.get_node_count()):
		var node_name = str(state.get_node_name(index))
		assert(
			not RELEASE_BLOCKED_MATCH_NODES.has(node_name),
			"release match scene should not include debug node {0}".format([node_name])
		)
