extends Node


func _ready():
	_assert_probability_is_clamped_to_valid_range()
	_assert_empty_or_zero_shares_return_null()
	_assert_zero_and_negative_shares_are_ignored()
	get_tree().quit()


func _assert_probability_is_clamped_to_valid_range():
	var wheel = Utils.RouletteWheel.new({"only": 1.0})
	assert(wheel.get_value(-0.1) == "only", "negative roulette probability should clamp to the first value")
	assert(wheel.get_value(1.1) == "only", "overflow roulette probability should clamp to the last value")
	assert(wheel.get_value(1.0 + 0.000001) == "only", "floating point overshoot should not crash roulette")


func _assert_empty_or_zero_shares_return_null():
	var empty_wheel = Utils.RouletteWheel.new({})
	assert(empty_wheel.get_value(0.5) == null, "empty roulette wheel should return null")

	var zero_wheel = Utils.RouletteWheel.new({"none": 0.0})
	assert(zero_wheel.get_value(0.5) == null, "roulette wheel without positive shares should return null")


func _assert_zero_and_negative_shares_are_ignored():
	var wheel = Utils.RouletteWheel.new({"skip_zero": 0.0, "skip_negative": -2.0, "winner": 3.0})
	assert(wheel.get_value(0.0) == "winner", "roulette should ignore zero and negative shares")
	assert(wheel.get_value(1.0) == "winner", "roulette should still resolve the only positive share")
