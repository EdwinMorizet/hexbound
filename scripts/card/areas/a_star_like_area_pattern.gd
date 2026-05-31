class_name AStarLikeAreaPattern
extends "res://scripts/card/areas/card_area_pattern.gd"

@export_range(1, 20, 1) var max_path_cost: int = 4
@export var include_start_hex: bool = true
@export var include_end_hex: bool = true


func get_required_input_steps() -> int:
	return 2


func is_step_valid(_origin_hex: Vector2i, candidate_hex: Vector2i, chosen_steps: Array[Vector2i]) -> bool:
	if chosen_steps.is_empty():
		return true
	var first_hex := chosen_steps[0]
	return CardHexMath.axial_distance(first_hex, candidate_hex) <= max_path_cost


func build_hover_preview_hexes(_origin_hex: Vector2i, hover_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return [hover_hex]
	return _build_path(chosen_steps[0], hover_hex)


func resolve_affected_hexes(_origin_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.size() < 2:
		return []
	return _build_path(chosen_steps[0], chosen_steps[1])


func _build_path(from_hex: Vector2i, to_hex: Vector2i) -> Array[Vector2i]:
	var path := CardHexMath.hex_line(from_hex, to_hex)
	if path.size() > max_path_cost + 1:
		path = path.slice(0, max_path_cost + 1)
	if not include_start_hex and not path.is_empty():
		path.remove_at(0)
	if not include_end_hex and not path.is_empty():
		path.remove_at(path.size() - 1)
	return path
