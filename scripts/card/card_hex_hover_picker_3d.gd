class_name CardHexHoverPicker3D
extends Node3D

signal hover_hex_changed(hex: Vector2i, has_valid_hex: bool)
signal target_hex_clicked(hex: Vector2i, has_valid_hex: bool)

@export var camera_path: NodePath
@export_flags_3d_physics var collision_mask: int = 1
@export var max_ray_distance: float = 400.0

var _last_hover_hex: Vector2i = Vector2i(2147483647, 2147483647)
var _has_last_hex: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_from_mouse()
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_update_hover_from_mouse()
			emit_signal("target_hex_clicked", _last_hover_hex, _has_last_hex)


func _update_hover_from_mouse() -> void:
	var camera := get_node_or_null(camera_path) as Camera3D
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if camera == null:
		_emit_hover(Vector2i.ZERO, false)
		return

	var viewport := get_viewport()
	if viewport == null:
		_emit_hover(Vector2i.ZERO, false)
		return

	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * max_ray_distance

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, collision_mask)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_emit_hover(Vector2i.ZERO, false)
		return

	var collider := hit.get("collider") as Node
	if collider == null:
		_emit_hover(Vector2i.ZERO, false)
		return

	var coord_owner := collider
	if not coord_owner.has_meta("coord_h"):
		coord_owner = collider.get_parent()
	if coord_owner == null or not coord_owner.has_meta("coord_h"):
		_emit_hover(Vector2i.ZERO, false)
		return

	var coord_h: Variant = coord_owner.get_meta("coord_h")
	if not (coord_h is Vector4):
		_emit_hover(Vector2i.ZERO, false)
		return

	var hex := Vector2i(int(coord_h.x), int(coord_h.y))
	_emit_hover(hex, true)


func _emit_hover(hex: Vector2i, has_valid_hex: bool) -> void:
	if has_valid_hex:
		if _has_last_hex and hex == _last_hover_hex:
			return
		_last_hover_hex = hex
		_has_last_hex = true
		emit_signal("hover_hex_changed", hex, true)
		return

	if _has_last_hex:
		_has_last_hex = false
		emit_signal("hover_hex_changed", Vector2i.ZERO, false)
