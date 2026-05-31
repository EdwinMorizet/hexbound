class_name TerrainHeightEffectDefinition
extends "res://scripts/card/effects/card_effect_definition.gd"

@export_range(-2, 2, 1) var delta_height: int = 1
@export_range(0, 5, 1) var clamp_min_height: int = 0
@export_range(0, 5, 1) var clamp_max_height: int = 5
@export var forbid_height_0_and_5: bool = true


func build_operations(context: Dictionary, affected_hexes: Array[Vector2i], _chosen_steps: Array[Vector2i]) -> Array[Dictionary]:
	var resolved_delta_height: int = delta_height
	if context.has("terrain_height_delta_override"):
		resolved_delta_height = int(context.get("terrain_height_delta_override", delta_height))
		resolved_delta_height = clampi(resolved_delta_height, -2, 2)
	var operations: Array[Dictionary] = []
	for hex: Vector2i in affected_hexes:
		operations.append({
			"operation": "terrain_height_delta",
			"hex": hex,
			"delta_height": resolved_delta_height,
			"clamp_min_height": clamp_min_height,
			"clamp_max_height": clamp_max_height,
			"forbid_height_0_and_5": forbid_height_0_and_5,
		})
	return operations
