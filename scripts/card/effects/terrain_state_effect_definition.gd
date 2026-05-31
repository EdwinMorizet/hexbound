class_name TerrainStateEffectDefinition
extends "res://scripts/card/effects/card_effect_definition.gd"

@export var state_name: String = "On Fire"
@export_range(1, 10, 1) var duration_turns: int = 2


func build_operations(_context: Dictionary, affected_hexes: Array[Vector2i], _chosen_steps: Array[Vector2i]) -> Array[Dictionary]:
	var operations: Array[Dictionary] = []
	for hex: Vector2i in affected_hexes:
		operations.append({
			"operation": "terrain_state_apply",
			"hex": hex,
			"state_name": state_name,
			"duration_turns": duration_turns,
		})
	return operations
