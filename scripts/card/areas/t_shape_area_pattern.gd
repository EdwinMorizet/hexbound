class_name TShapeAreaPattern
extends "res://scripts/card/areas/card_area_pattern.gd"

@export_range(1, 8, 1) var arm_length: int = 1
@export var include_center: bool = true


func build_hover_preview_hexes(origin_hex: Vector2i, hover_hex: Vector2i, _chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	return _build_shape(origin_hex, hover_hex)


func resolve_affected_hexes(origin_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return []
	return _build_shape(origin_hex, chosen_steps[0])


func _build_shape(origin_hex: Vector2i, center_hex: Vector2i) -> Array[Vector2i]:
	var affected: Array[Vector2i] = []
	if include_center:
		affected.append(center_hex)

	var forward := CardHexMath.nearest_direction(origin_hex, center_hex)
	for i: int in range(1, arm_length + 1):
		affected.append(center_hex + forward * i)

	var perpendiculars := CardHexMath.direction_perpendiculars(forward)
	for side_direction: Vector2i in perpendiculars:
		for i: int in range(1, arm_length + 1):
			affected.append(center_hex + side_direction * i)
	return CardHexMath.unique_hexes(affected)
