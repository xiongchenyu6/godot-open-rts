extends Node

enum PlayerType {
	NONE = 0,
	HUMAN = 1,
	SIMPLE_CLAIRVOYANT_AI = 2,
	SIMPLE_CLAIRVOYANT_AI_EASY = 3,
	SIMPLE_CLAIRVOYANT_AI_HARD = 4,
	SIMPLE_CLAIRVOYANT_AI_BEGINNER = 5,
}


class Match:
	extends "res://source/match/MatchConstants.gd"

	class Player:
		const CONTROLLER_SCENES = {
			PlayerType.HUMAN: preload("res://source/match/players/human/Human.tscn"),
			PlayerType.SIMPLE_CLAIRVOYANT_AI_BEGINNER:
			preload("res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.tscn"),
			PlayerType.SIMPLE_CLAIRVOYANT_AI_EASY:
			preload("res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.tscn"),
			PlayerType.SIMPLE_CLAIRVOYANT_AI:
			preload("res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.tscn"),
			PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD:
			preload("res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.tscn"),
		}


class Player:
	const COLORS = [
		Color("2d7dff"),
		Color("ff4f64"),
		Color("2acf75"),
		Color("b96cff"),
		Color("ff9f1c"),
		Color("20cfe8"),
		Color("f4d23a"),
		Color("f05deb"),
		Color("0aff0a"),
		Color("441fff"),
		Color("8bcc08"),
		Color("3976b2"),
		Color("b26239"),
		Color("b23976"),
		Color("ff0a0a"),
		Color("d60aff"),
		Color("1fffda"),
		Color("1836cc"),
		Color("ff1f8f"),
		Color("b22407"),
	]


# gdlint: ignore=class-variable-name
var OPTIONS_FILE_PATH:
	set(_value):
		pass
	get:
		return (
			"user://options.tres"
			if not FeatureFlags.save_user_files_in_tmp
			else "res://tmp/options.tres"
		)
