class_name CardEffectDefinition
extends Resource

@export var effect_id: String = ""


func validate(_context: Dictionary, affected_hexes: Array[Vector2i], _chosen_steps: Array[Vector2i]) -> bool:
	return not affected_hexes.is_empty()


func build_operations(_context: Dictionary, _affected_hexes: Array[Vector2i], _chosen_steps: Array[Vector2i]) -> Array[Dictionary]:
	return []


func apply(context: Dictionary, affected_hexes: Array[Vector2i], chosen_steps: Array[Vector2i]) -> Array[Dictionary]:
	if not validate(context, affected_hexes, chosen_steps):
		return []
	return build_operations(context, affected_hexes, chosen_steps)
