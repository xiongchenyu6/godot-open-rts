extends Node

const Match = preload("res://source/match/MatchUtils.gd")


class Set:
	extends "res://source/utils/Set.gd"

	static func from_array(array):
		var a_set = Set.new()
		for item in array:
			a_set.add(item)
		return a_set

	static func subtracted(minuend, subtrahend):
		var difference = Set.new()
		for item in minuend.iterate():
			if not subtrahend.has(item):
				difference.add(item)
		return difference


class Dict:
	static func items(dict):
		var pairs = []
		for key in dict:
			pairs.append([key, dict[key]])
		return pairs


class Float:
	static func is_equal_approx_with_epsilon(a: float, b: float, epsilon):
		return abs(a - b) <= epsilon


class Colour:
	static func is_equal_approx_with_epsilon(a: Color, b: Color, epsilon: float):
		return (
			Float.is_equal_approx_with_epsilon(a.r, b.r, epsilon)
			and Float.is_equal_approx_with_epsilon(a.g, b.g, epsilon)
			and Float.is_equal_approx_with_epsilon(a.b, b.b, epsilon)
		)


class NodeEx:
	static func find_parent_with_group(node, group_for_parent_to_be_in):
		var ancestor = node.get_parent()
		while ancestor != null:
			if ancestor.is_in_group(group_for_parent_to_be_in):
				return ancestor
			ancestor = ancestor.get_parent()
		return null


class Arr:
	static func sum(array):
		var total = 0
		for item in array:
			total += item
		return total


class RouletteWheel:
	var _values_w_sorted_normalized_shares = []

	func _init(value_to_share_mapping):
		var total_share = 0.0
		for share in value_to_share_mapping.values():
			if share > 0.0:
				total_share += share
		if total_share <= 0.0:
			push_warning("Roulette wheel has no positive shares")
			return
		for value in value_to_share_mapping:
			var share = value_to_share_mapping[value]
			if share <= 0.0:
				continue
			var normalized_share = share / total_share
			_values_w_sorted_normalized_shares.append([value, normalized_share])
		for i in range(1, _values_w_sorted_normalized_shares.size()):
			_values_w_sorted_normalized_shares[i][1] += _values_w_sorted_normalized_shares[i - 1][1]

	func get_value(probability):
		if _values_w_sorted_normalized_shares.is_empty():
			return null
		var normalized_probability = clampf(probability, 0.0, 1.0)
		for tuple in _values_w_sorted_normalized_shares:
			var value = tuple[0]
			var accumulated_share = tuple[1]
			if normalized_probability <= accumulated_share:
				return value
		return _values_w_sorted_normalized_shares[-1][0]
