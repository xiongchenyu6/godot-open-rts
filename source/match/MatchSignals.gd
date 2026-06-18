extends Node

# requests
signal deselect_all_units
signal setup_and_spawn_unit(unit, transform, player)
signal place_structure(structure_prototype)
signal schedule_navigation_rebake(domain)
signal navigate_unit_to_rally_point(unit, rally_point)  # currently, only for human players
signal attack_move_requested
signal patrol_requested
signal rally_point_requested
signal support_power_targeting_started(power_id)
signal support_power_targeting_finished(power_id)
signal minimap_terrain_targeted(position)
signal unit_group_assigned(group_id, units)
signal unit_group_cleared(group_id)
signal unit_command_confirmed(command_key, units)

# notifications
signal match_started
signal match_aborted
signal match_finished_with_victory
signal match_finished_with_defeat
signal visible_player_changed(previous_player, new_player)
signal terrain_targeted(position)
signal unit_spawned(unit)
signal unit_targeted(unit)
signal unit_selected(unit)
signal unit_deselected(unit)
signal unit_damaged(unit)
signal unit_died(unit)
signal unit_production_started(unit_prototype, producer_unit)
signal unit_production_blocked(unit_prototype, producer_unit)
signal unit_production_finished(unit, producer_unit)
signal unit_construction_started(unit)
signal unit_construction_canceled(unit)
signal unit_construction_finished(unit)
signal unit_repair_started(unit)
signal unit_sell_started(unit)
signal unit_sold(unit)
signal unit_captured(unit, previous_player, new_player)
signal unit_promoted(unit, rank)
signal supply_crate_collected(crate, unit, effect_type)
signal support_power_activated(power_id, player, target_position)
signal support_power_charging(power_id, player, charge_seconds)
signal support_power_ready(power_id, player)
signal not_enough_resources_for_production(player)
signal not_enough_resources_for_construction(player)
signal battle_event_recorded(position)
signal battle_event_ping_requested(position, event_type)
