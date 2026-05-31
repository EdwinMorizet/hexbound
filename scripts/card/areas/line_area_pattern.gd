class_name LineAreaPattern
extends "res://scripts/card/areas/card_area_pattern.gd"

@export_range(1, 20, 1) var min_length: int = 1
@export_range(1, 20, 1) var max_length: int = 3
@export var include_origin: bool = false


func is_step_valid(origin_hex: Vector2i, candidate_hex: Vector2i, _chosen_steps: Array[Vector2i]) -> bool:
	var distance := CardHexMath.axial_distance(origin_hex, candidate_hex)
	return distance >= min_length and distance <= max_length


func build_hover_preview_hexes(origin_hex: Vector2i, hover_hex: Vector2i, _chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	var line := CardHexMath.hex_line(origin_hex, hover_hex)
	if line.size() > max_length + 1:
		line = line.slice(0, max_length + 1)
	if not include_origin and not line.is_empty():
		line.remove_at(0)
	return line


func resolve_affected_hexes(origin_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return []
	return build_hover_preview_hexes(origin_hex, chosen_steps[0], [])
