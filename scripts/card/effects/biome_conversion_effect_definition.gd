class_name BiomeConversionEffectDefinition
extends "res://scripts/card/effects/card_effect_definition.gd"

@export var from_biome_name: String = "Desert"
@export var to_biome_name: String = "Plain"
@export var alternate_from_biome_name: String = "Plain"
@export var alternate_to_biome_name: String = "Forest"


func build_operations(_context: Dictionary, affected_hexes: Array[Vector2i], _chosen_steps: Array[Vector2i]) -> Array[Dictionary]:
	var operations: Array[Dictionary] = []
	for hex: Vector2i in affected_hexes:
		operations.append({
			"operation": "biome_convert",
			"hex": hex,
			"from_biome_name": from_biome_name,
			"to_biome_name": to_biome_name,
			"alternate_from_biome_name": alternate_from_biome_name,
			"alternate_to_biome_name": alternate_to_biome_name,
		})
	return operations
