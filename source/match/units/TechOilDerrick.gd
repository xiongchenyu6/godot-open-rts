extends "res://source/match/units/Structure.gd"

var resource_income_a = 1
var resource_income_b = 0
var income_interval_s = 6.0
var capture_bonus_a = 4
var capture_bonus_b = 0

var _income_timer = null


func _ready():
	await super()
	_setup_income_timer()


func capture_by(capturing_player):
	var captured = super(capturing_player)
	if captured and _can_pay_income_to(capturing_player):
		capturing_player.resource_a += capture_bonus_a
		capturing_player.resource_b += capture_bonus_b
	return captured


func _setup_income_timer():
	_income_timer = Timer.new()
	_income_timer.wait_time = maxf(0.1, income_interval_s)
	_income_timer.timeout.connect(_on_income_timer_timeout)
	add_child(_income_timer)
	_income_timer.start()


func _on_income_timer_timeout():
	if not is_constructed() or not _can_pay_income_to(player):
		return
	player.resource_a += resource_income_a
	player.resource_b += resource_income_b


func _can_pay_income_to(candidate_player):
	return (
		candidate_player != null
		and (
			not ("participates_in_match" in candidate_player)
			or candidate_player.participates_in_match
		)
	)
