class_name LShapeAreaPattern
extends "res://scripts/card/areas/card_area_pattern.gd"

@export_range(1, 8, 1) var leg_a: int = 2
@export_range(1, 8, 1) var leg_b: int = 2
@export var turn_clockwise: bool = true


func build_hover_preview_hexes(origin_hex: Vector2i, hover_hex: Vector2i, _chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	return _build_shape(origin_hex, hover_hex)


func resolve_affected_hexes(origin_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return []
	return _build_shape(origin_hex, chosen_steps[0])


func _build_shape(origin_hex: Vector2i, anchor_hex: Vector2i) -> Array[Vector2i]:
	var primary_direction := CardHexMath.nearest_direction(origin_hex, anchor_hex)
	var perpendiculars := CardHexMath.direction_perpendiculars(primary_direction)
	var turn_direction := perpendiculars[1] if turn_clockwise else perpendiculars[0]

	var affected: Array[Vector2i] = [anchor_hex]
	var corner := anchor_hex
	for i: int in range(1, leg_a + 1):
		corner = anchor_hex + primary_direction * i
		affected.append(corner)

	for i: int in range(1, leg_b + 1):
		affected.append(corner + turn_direction * i)
	return CardHexMath.unique_hexes(affected)
