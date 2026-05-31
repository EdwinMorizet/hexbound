class_name UnitDisplacementEffectDefinition
extends "res://scripts/card/effects/card_effect_definition.gd"

@export_range(1, 4, 1) var displacement_distance: int = 1
@export var affects_friendly: bool = true
@export var affects_enemy: bool = true
@export var ignore_height_restrictions: bool = true


func build_operations(_context: Dictionary, affected_hexes: Array[Vector2i], _chosen_steps: Array[Vector2i]) -> Array[Dictionary]:
	var operations: Array[Dictionary] = []
	for hex: Vector2i in affected_hexes:
		operations.append({
			"operation": "unit_displace",
			"hex": hex,
			"displacement_distance": displacement_distance,
			"affects_friendly": affects_friendly,
			"affects_enemy": affects_enemy,
			"ignore_height_restrictions": ignore_height_restrictions,
		})
	return operations
