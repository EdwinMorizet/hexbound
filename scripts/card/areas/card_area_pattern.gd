class_name CardAreaPattern
extends Resource


func get_required_input_steps() -> int:
	return 1


func is_step_valid(_origin_hex: Vector2i, _candidate_hex: Vector2i, _chosen_steps: Array[Vector2i]) -> bool:
	return true


func build_hover_preview_hexes(origin_hex: Vector2i, hover_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return [hover_hex]
	return resolve_affected_hexes(origin_hex, chosen_steps)


func resolve_affected_hexes(_origin_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Array[Vector2i]:
	if chosen_steps.is_empty():
		return []
	return [chosen_steps[chosen_steps.size() - 1]]
