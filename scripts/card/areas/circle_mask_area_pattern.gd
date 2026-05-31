class_name CircleMaskAreaPattern
extends "res://scripts/card/areas/card_area_pattern.gd"

@export_range(0, 10, 1) var outer_radius: int = 1
@export_range(0, 10, 1) var inner_radius: int = 0


func build_hover_preview_hexes(_origin_hex: Vector2i, hover_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	var center := hover_hex
	if not chosen_steps.is_empty():
		center = chosen_steps[chosen_steps.size() - 1]
	return CardHexMath.hex_disc_mask(center, outer_radius, inner_radius)


func resolve_affected_hexes(_origin_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return []
	return CardHexMath.hex_disc_mask(chosen_steps[0], outer_radius, inner_radius)
