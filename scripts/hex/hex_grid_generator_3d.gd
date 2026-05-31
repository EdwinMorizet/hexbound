@tool
class_name HexGridGenerator3D
extends Node3D

@export_group("Behavior")
## Generates immediately when the node enters the scene tree.
@export var auto_generate_on_ready: bool = true
## Publishes generated tiles to the autoload singleton when available.
@export var sync_with_autoload: bool = true
## Clears previously generated tiles before rebuilding the grid.
@export var clear_before_generate: bool = true
## Writes generated nodes into the edited scene when in the editor.
@export var persist_generated_nodes_in_scene: bool = false

@export_group("Grid")
## The hex map side length in tiles.
@export_range(2, 16, 1) var side_length: int = 5
## Seed used for deterministic generation.
@export_range(-2147483648, 2147483647, 1) var world_seed: int = 1337
## Hex radius used for world-space placement.
@export_range(0.01, 100.0, 0.01) var tile_radius: float = 1.0
## Total visible height of each generated hex prism.
@export_range(0.01, 100.0, 0.01) var tile_thickness: float = 0.25
## Vertical step between tile height levels.
@export_range(0.01, 10.0, 0.01) var height_step: float = 0.3
## Base world Y position for the generated board.
@export_range(-100.0, 100.0, 0.01) var base_y: float = 0.0

@export_group("Collision")
## Generates collision bodies for each hex tile.
@export var generate_collision: bool = true

@export_group("Card Demo")
## Enables in-scene card selection and hex targeting preview demo at runtime.
@export var enable_card_targeting_demo: bool = false
## Test hand card resources used by the targeting demo.
@export var demo_card_paths: Array[String] = [
	"res://data/card/fire/flame_jolt.tres",
	"res://data/card/water/tide_step.tres",
	"res://data/card/earth/stone_rampart.tres",
	"res://data/card/wind/gale_push.tres",
]
## Preview highlight color for affected tiles.
@export var preview_highlight_color: Color = Color(0.95, 0.85, 0.35, 0.7)

@export_group("Camera Controls")
## Enables RTS-like controls on Camera3D in runtime preview scenes.
@export var enable_rts_camera_controls: bool = true
## Camera node controlled by the RTS input.
@export var rts_camera_path: NodePath = NodePath("Camera3D")
## Base movement speed for panning the look target on X/Z.
@export_range(0.1, 100.0, 0.1) var rts_pan_speed: float = 10.0
## Distance added/removed per mouse wheel step.
@export_range(0.1, 20.0, 0.1) var rts_zoom_step: float = 1.25
## Minimum camera-to-target distance.
@export_range(0.5, 100.0, 0.1) var rts_min_zoom_distance: float = 6.0
## Maximum camera-to-target distance.
@export_range(1.0, 200.0, 0.1) var rts_max_zoom_distance: float = 30.0
## Pitch when zoomed in.
@export_range(-89.0, 0.0, 0.1) var rts_near_pitch_degrees: float = -55.0
## Pitch when zoomed out; keep at 0 for a flatter RTS view.
@export_range(-89.0, 0.0, 0.1) var rts_far_pitch_degrees: float = 0.0
## Yaw around the target.
@export_range(-180.0, 180.0, 0.1) var rts_yaw_degrees: float = 30.0
## Vertical offset above the sampled tile top.
@export_range(-2.0, 5.0, 0.01) var rts_target_height_offset: float = 0.1

@export_group("Noise")
## Frequency used for elevation noise.
@export_range(0.001, 1.0, 0.001) var elevation_frequency: float = 0.09
## Octaves used for elevation noise.
@export_range(1, 8, 1) var elevation_octaves: int = 4
## Frequency used for moisture noise.
@export_range(0.001, 1.0, 0.001) var moisture_frequency: float = 0.12
## Octaves used for moisture noise.
@export_range(1, 8, 1) var moisture_octaves: int = 3
## Moisture threshold below which height 1-2 becomes desert.
@export_range(-1.0, 1.0, 0.01) var desert_moisture_threshold: float = -0.05
## Moisture threshold above which higher land becomes forest.
@export_range(-1.0, 1.0, 0.01) var forest_moisture_threshold: float = 0.18

@export_tool_button("Regenerate") var regenerate_in_editor: Callable = _regenerate_with_new_seed

var _generation_core: HexGridGenerationCore = HexGridGenerationCore.new()
var _visual_core: HexGridVisualCore = HexGridVisualCore.new()
var _targeting_controller: CardTargetingController
var _hover_picker: CardHexHoverPicker3D
var _demo_hud: CardTargetingDemoHud
var _loaded_demo_cards: Array[CardDefinition] = []
var _player_elements: Dictionary[ElementSystem.ElementType, int] = {}
var _selected_height_delta: int = 1
var _current_hover_hex: Vector2i = Vector2i.ZERO
var _has_hover_hex: bool = false
var _hex_tile_index: Dictionary[Vector2i, Node3D] = {}
var _runtime_heights: Dictionary[Vector2i, int] = {}
var _runtime_biomes: Dictionary[Vector2i, int] = {}
var _runtime_states: Dictionary[Vector2i, Dictionary] = {}
var _active_highlight_meshes: Array[MeshInstance3D] = []
var _preview_overlay_material: StandardMaterial3D
var _rts_camera: Camera3D
var _rts_target_position: Vector3 = Vector3.ZERO
var _rts_zoom_distance: float = 14.0
var _rts_bounds_min_xz: Vector2 = Vector2.ZERO
var _rts_bounds_max_xz: Vector2 = Vector2.ZERO
var _rts_has_bounds: bool = false


func _ready() -> void:
	if auto_generate_on_ready:
		call_deferred("regenerate")
	if enable_rts_camera_controls and not Engine.is_editor_hint():
		call_deferred("_setup_rts_camera_controls")
	if enable_card_targeting_demo and not Engine.is_editor_hint():
		call_deferred("_setup_card_targeting_demo")


func regenerate() -> void:
	if clear_before_generate:
		_clear_tiles()
	var tiles := _generate_tiles()
	_render_tiles(tiles)
	_index_hex_tiles()
	_clear_preview_highlight()
	if enable_rts_camera_controls and not Engine.is_editor_hint():
		_setup_rts_camera_controls()


func _process(delta: float) -> void:
	if not _can_update_rts_camera():
		return
	_update_rts_camera_pan(delta)
	_update_rts_target_height_from_hex()
	_apply_rts_camera_transform()


func _regenerate_with_new_seed() -> void:
	if Engine.is_editor_hint():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		world_seed = rng.randi()
	regenerate()


func _generate_tiles() -> Array[HexGridTileData]:
	_sync_core_from_exports()
	var tiles := _generation_core.generate_grid()
	_visual_core.tile_radius = tile_radius
	_visual_core.tile_thickness = tile_thickness
	if sync_with_autoload and not Engine.is_editor_hint() and has_node("/root/HexGridAPI"):
		var api: HexGridAPI = get_node("/root/HexGridAPI")
		api.set_tiles(tiles)
	return tiles


func _render_tiles(tiles: Array[HexGridTileData]) -> void:
	var root := _get_or_create_tiles_root()
	for tile in tiles:
		var coord_h: Vector4 = tile.coord_h
		var biome: int = tile.biome
		var world_position: Vector3 = tile.world_position
		var cell_height := tile_thickness

		var tile_root := Node3D.new()
		tile_root.name = "Hex_%d_%d_%d" % [int(coord_h.x), int(coord_h.y), int(coord_h.z)]
		tile_root.position = Vector3(
			world_position.x,
			base_y + world_position.y,
			world_position.z
		)
		tile_root.set_meta("coord_h", coord_h)
		tile_root.set_meta("biome", biome)
		root.add_child(tile_root)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _visual_core.build_hex_mesh(max(tile_thickness, float(tile.height) * height_step))
		mesh_instance.material_override = _visual_core.build_biome_material(biome)
		mesh_instance.position = Vector3(0.0, cell_height * 0.5, 0.0)
		mesh_instance.rotation_degrees = Vector3(0.0, 30.0, 0.0)
		tile_root.add_child(mesh_instance)

		if generate_collision:
			_add_collision(tile_root, mesh_instance.mesh)

		if Engine.is_editor_hint() and persist_generated_nodes_in_scene:
			var scene_owner := _get_scene_owner()
			_assign_owner_recursive(tile_root, scene_owner)


func _get_or_create_tiles_root() -> Node3D:
	if has_node("HexTiles"):
		return get_node("HexTiles") as Node3D
	var root := Node3D.new()
	root.name = "HexTiles"
	add_child(root)
	if Engine.is_editor_hint() and persist_generated_nodes_in_scene:
		root.owner = _get_scene_owner()
	return root


func _clear_tiles() -> void:
	if not has_node("HexTiles"):
		return
	var root: Node3D = get_node("HexTiles")
	for child in root.get_children():
		child.queue_free()


func _add_collision(tile_root: Node3D, mesh: Mesh) -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.position = Vector3(0.0, tile_thickness * 0.5, 0.0)
	if tile_root.has_meta("coord_h"):
		body.set_meta("coord_h", tile_root.get_meta("coord_h"))

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape"

	collision_shape.shape = _visual_core.build_collider_shape(mesh)

	body.add_child(collision_shape)
	tile_root.add_child(body)


func _sync_core_from_exports() -> void:
	_generation_core.side_length = side_length
	_generation_core.map_seed = world_seed
	_generation_core.elevation_frequency = elevation_frequency
	_generation_core.elevation_octaves = elevation_octaves
	_generation_core.moisture_frequency = moisture_frequency
	_generation_core.moisture_octaves = moisture_octaves
	_generation_core.desert_moisture_threshold = desert_moisture_threshold
	_generation_core.forest_moisture_threshold = forest_moisture_threshold
	_generation_core.tile_radius = tile_radius
	_generation_core.height_step = height_step


func _get_scene_owner() -> Node:
	if get_tree() == null:
		return self
	if get_tree().edited_scene_root != null:
		return get_tree().edited_scene_root
	return self


func _assign_owner_recursive(node: Node, node_owner: Node) -> void:
	node.owner = node_owner
	for child in node.get_children():
		_assign_owner_recursive(child, node_owner)


func _setup_card_targeting_demo() -> void:
	_targeting_controller = CardTargetingController.new()
	_targeting_controller.name = "CardTargetingController"
	add_child(_targeting_controller)

	_hover_picker = CardHexHoverPicker3D.new()
	_hover_picker.name = "CardHexHoverPicker3D"
	_hover_picker.camera_path = NodePath("../Camera3D")
	add_child(_hover_picker)

	_targeting_controller.preview_area_changed.connect(_on_preview_area_changed)
	_targeting_controller.effect_resolved.connect(_on_effect_resolved)
	_targeting_controller.selectable_cards_changed.connect(_on_selectable_cards_changed)
	_targeting_controller.card_selected.connect(_on_card_selected)
	_targeting_controller.chosen_steps_changed.connect(_on_chosen_steps_changed)
	_hover_picker.hover_hex_changed.connect(_on_hover_hex_changed)
	_hover_picker.target_hex_clicked.connect(_on_target_hex_clicked)

	_demo_hud = CardTargetingDemoHud.new()
	_demo_hud.name = "CardTargetingDemoHud"
	add_child(_demo_hud)
	_demo_hud.card_pick_requested.connect(_on_hud_card_pick_requested)
	_demo_hud.cancel_requested.connect(_on_hud_cancel_requested)
	_demo_hud.height_delta_choice_requested.connect(_on_hud_height_delta_choice_requested)

	_preview_overlay_material = StandardMaterial3D.new()
	_preview_overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_overlay_material.albedo_color = preview_highlight_color
	_preview_overlay_material.emission_enabled = true
	_preview_overlay_material.emission = preview_highlight_color
	_preview_overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_load_demo_cards()
	_targeting_controller.set_hand_cards(_loaded_demo_cards)
	_player_elements = {
		ElementSystem.ElementType.FIRE: 3,
		ElementSystem.ElementType.WATER: 3,
		ElementSystem.ElementType.EARTH: 3,
		ElementSystem.ElementType.WIND: 3,
	}
	_targeting_controller.set_player_elements(_player_elements)
	_demo_hud.set_element_pool_text(_player_elements)
	_demo_hud.set_height_mode_visible(false)
	_demo_hud.set_targeting_progress([], 0)
	_index_hex_tiles()


func _unhandled_input(event: InputEvent) -> void:
	if enable_rts_camera_controls and not Engine.is_editor_hint():
		_handle_rts_camera_zoom_input(event)

	if not enable_card_targeting_demo or Engine.is_editor_hint():
		return
	if _targeting_controller == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_targeting_controller.cancel_targeting()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var digit := _keycode_to_digit(key_event.keycode)
		if digit == -1:
			return
		var card_index := digit - 1
		var selectable := _targeting_controller.get_selectable_cards()
		if card_index < 0 or card_index >= selectable.size():
			return
		var origin := _current_hover_hex if _has_hover_hex else Vector2i.ZERO
		_targeting_controller.try_select_card(selectable[card_index], origin)


func _keycode_to_digit(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 1
		KEY_2:
			return 2
		KEY_3:
			return 3
		KEY_4:
			return 4
		KEY_5:
			return 5
		_:
			return -1


func _load_demo_cards() -> void:
	_loaded_demo_cards.clear()
	for card_path: String in demo_card_paths:
		var card := load(card_path) as CardDefinition
		if card != null:
			_loaded_demo_cards.append(card)


func _index_hex_tiles() -> void:
	_hex_tile_index.clear()
	_runtime_heights.clear()
	_runtime_biomes.clear()
	_runtime_states.clear()
	_rts_has_bounds = false
	if not has_node("HexTiles"):
		return
	var root: Node3D = get_node("HexTiles")
	for child: Node in root.get_children():
		var tile_root := child as Node3D
		if tile_root == null:
			continue
		if not tile_root.has_meta("coord_h"):
			continue
		var coord_h: Variant = tile_root.get_meta("coord_h")
		if coord_h is Vector4:
			var hex := Vector2i(int(coord_h.x), int(coord_h.y))
			_hex_tile_index[hex] = tile_root
			_runtime_heights[hex] = int(coord_h.w)
			_runtime_biomes[hex] = int(tile_root.get_meta("biome", HexGridAPI.Biome.PLAIN))
			var tile_xz := Vector2(tile_root.global_position.x, tile_root.global_position.z)
			if not _rts_has_bounds:
				_rts_bounds_min_xz = tile_xz
				_rts_bounds_max_xz = tile_xz
				_rts_has_bounds = true
			else:
				_rts_bounds_min_xz.x = minf(_rts_bounds_min_xz.x, tile_xz.x)
				_rts_bounds_min_xz.y = minf(_rts_bounds_min_xz.y, tile_xz.y)
				_rts_bounds_max_xz.x = maxf(_rts_bounds_max_xz.x, tile_xz.x)
				_rts_bounds_max_xz.y = maxf(_rts_bounds_max_xz.y, tile_xz.y)


func _setup_rts_camera_controls() -> void:
	if Engine.is_editor_hint() or not enable_rts_camera_controls:
		return
	_rts_camera = get_node_or_null(rts_camera_path) as Camera3D
	if _rts_camera == null:
		return
	if _hex_tile_index.is_empty():
		_index_hex_tiles()

	var center_hex := Vector2i.ZERO
	if not _hex_tile_index.has(center_hex):
		center_hex = _find_nearest_hex_for_xz(Vector2(_rts_camera.global_position.x, _rts_camera.global_position.z))
	if _hex_tile_index.has(center_hex):
		var center_tile := _hex_tile_index[center_hex] as Node3D
		if center_tile != null:
			_rts_target_position = center_tile.global_position
			_rts_target_position.y = _get_hex_surface_y(center_hex) + rts_target_height_offset

	var forward := -_rts_camera.global_transform.basis.z
	var flat_forward := Vector2(forward.x, forward.z)
	if flat_forward.length_squared() > 0.0001:
		rts_yaw_degrees = rad_to_deg(atan2(flat_forward.x, flat_forward.y))

	_rts_zoom_distance = clampf((_rts_camera.global_position - _rts_target_position).length(), rts_min_zoom_distance, rts_max_zoom_distance)
	_apply_rts_camera_transform()


func _can_update_rts_camera() -> bool:
	if Engine.is_editor_hint() or not enable_rts_camera_controls:
		return false
	if _rts_camera == null:
		_rts_camera = get_node_or_null(rts_camera_path) as Camera3D
	return _rts_camera != null


func _handle_rts_camera_zoom_input(event: InputEvent) -> void:
	if _rts_camera == null:
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_rts_zoom_distance = clampf(_rts_zoom_distance - rts_zoom_step, rts_min_zoom_distance, rts_max_zoom_distance)
		MOUSE_BUTTON_WHEEL_DOWN:
			_rts_zoom_distance = clampf(_rts_zoom_distance + rts_zoom_step, rts_min_zoom_distance, rts_max_zoom_distance)
		_:
			return


func _update_rts_camera_pan(delta: float) -> void:
	if _rts_camera == null:
		return

	var input_axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_Z):
		input_axis.y += 1.0
	if Input.is_key_pressed(KEY_S):
		input_axis.y -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_axis.x += 1.0
	if Input.is_key_pressed(KEY_Q):
		input_axis.x -= 1.0

	if input_axis == Vector2.ZERO:
		return

	input_axis = input_axis.normalized()
	var zoom_t := inverse_lerp(rts_min_zoom_distance, rts_max_zoom_distance, _rts_zoom_distance)
	var speed_scale := lerpf(0.6, 1.8, zoom_t)

	var yaw_rad := deg_to_rad(rts_yaw_degrees)
	var forward_flat := Vector3(sin(yaw_rad), 0.0, cos(yaw_rad)).normalized()
	var right_flat := forward_flat.cross(Vector3.UP).normalized()
	var move := (right_flat * input_axis.x + forward_flat * input_axis.y) * rts_pan_speed * speed_scale * delta
	_rts_target_position += move

	if _rts_has_bounds:
		_rts_target_position.x = clampf(_rts_target_position.x, _rts_bounds_min_xz.x, _rts_bounds_max_xz.x)
		_rts_target_position.z = clampf(_rts_target_position.z, _rts_bounds_min_xz.y, _rts_bounds_max_xz.y)


func _update_rts_target_height_from_hex() -> void:
	if _hex_tile_index.is_empty():
		return
	var hex := _find_nearest_hex_for_xz(Vector2(_rts_target_position.x, _rts_target_position.z))
	if hex == Vector2i(999999, 999999):
		return
	_rts_target_position.y = _get_hex_surface_y(hex) + rts_target_height_offset


func _apply_rts_camera_transform() -> void:
	if _rts_camera == null:
		return
	var zoom_t := inverse_lerp(rts_min_zoom_distance, rts_max_zoom_distance, _rts_zoom_distance)
	var pitch_deg := lerpf(rts_far_pitch_degrees, rts_near_pitch_degrees, zoom_t)
	var pitch_rad := deg_to_rad(pitch_deg)
	var yaw_rad := deg_to_rad(rts_yaw_degrees)

	var forward := Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	).normalized()

	var camera_position := _rts_target_position - forward * _rts_zoom_distance
	_rts_camera.global_position = camera_position
	_rts_camera.look_at(_rts_target_position, Vector3.UP)


func _find_nearest_hex_for_xz(world_xz: Vector2) -> Vector2i:
	if _hex_tile_index.is_empty():
		return Vector2i(999999, 999999)

	var best_hex := Vector2i(999999, 999999)
	var best_distance_sq := INF
	for hex: Vector2i in _hex_tile_index.keys():
		var tile_root := _hex_tile_index[hex] as Node3D
		if tile_root == null:
			continue
		var tile_xz := Vector2(tile_root.global_position.x, tile_root.global_position.z)
		var dist_sq := tile_xz.distance_squared_to(world_xz)
		if dist_sq < best_distance_sq:
			best_distance_sq = dist_sq
			best_hex = hex
	return best_hex


func _get_hex_surface_y(hex: Vector2i) -> float:
	if not _runtime_heights.has(hex):
		return base_y
	var height: int = _runtime_heights.get(hex, 0)
	var mesh_height: float = max(tile_thickness, float(height) * height_step)
	return base_y + float(height) * height_step + mesh_height


func _on_selectable_cards_changed(selectable_cards: Array[CardDefinition]) -> void:
	if _demo_hud != null:
		_demo_hud.set_selectable_cards(selectable_cards)


func _on_card_selected(card: CardDefinition) -> void:
	if _demo_hud == null:
		return
	_demo_hud.set_selected_card(card)
	_demo_hud.set_selectable_cards(_targeting_controller.get_selectable_cards())
	if card != null and card.card_id == "raise_lower":
		_selected_height_delta = 1
		_targeting_controller.set_effect_context({"terrain_height_delta_override": _selected_height_delta})
		_demo_hud.set_height_mode_visible(true)
		_demo_hud.set_height_mode(_selected_height_delta)
	else:
		_targeting_controller.set_effect_context({})
		_demo_hud.set_height_mode_visible(false)


func _on_chosen_steps_changed(chosen_steps: Array[Vector2i], required_steps: int) -> void:
	if _demo_hud == null:
		return
	if required_steps == 0:
		_demo_hud.set_selected_card(null)
		_demo_hud.set_height_mode_visible(false)
		_targeting_controller.set_effect_context({})
	_demo_hud.set_targeting_progress(chosen_steps, required_steps)


func _on_hover_hex_changed(hex: Vector2i, has_valid_hex: bool) -> void:
	_has_hover_hex = has_valid_hex
	if not has_valid_hex:
		_clear_preview_highlight()
		return
	_current_hover_hex = hex
	if _targeting_controller != null:
		_targeting_controller.update_hover_hex(hex)


func _on_target_hex_clicked(hex: Vector2i, has_valid_hex: bool) -> void:
	if not has_valid_hex:
		return
	if _targeting_controller != null:
		_targeting_controller.confirm_target_hex(hex)


func _on_hud_card_pick_requested(card: CardDefinition) -> void:
	if _targeting_controller == null:
		return
	var origin := _current_hover_hex if _has_hover_hex else Vector2i.ZERO
	_targeting_controller.try_select_card(card, origin)


func _on_hud_cancel_requested() -> void:
	if _targeting_controller != null:
		_targeting_controller.cancel_targeting()


func _on_hud_height_delta_choice_requested(delta_height: int) -> void:
	_selected_height_delta = 1 if delta_height >= 0 else -1
	if _demo_hud != null:
		_demo_hud.set_height_mode(_selected_height_delta)
	if _targeting_controller != null and _targeting_controller.get_selected_card() != null:
		if _targeting_controller.get_selected_card().card_id == "raise_lower":
			_targeting_controller.set_effect_context({"terrain_height_delta_override": _selected_height_delta})


func _on_preview_area_changed(preview_hexes: Array[Vector2i]) -> void:
	_clear_preview_highlight()
	for hex: Vector2i in preview_hexes:
		var tile_root := _hex_tile_index.get(hex, null) as Node3D
		if tile_root == null:
			continue
		for child: Node in tile_root.get_children():
			var mesh := child as MeshInstance3D
			if mesh == null:
				continue
			mesh.material_overlay = _preview_overlay_material
			_active_highlight_meshes.append(mesh)
			break


func _clear_preview_highlight() -> void:
	for mesh: MeshInstance3D in _active_highlight_meshes:
		if mesh != null:
			mesh.material_overlay = null
	_active_highlight_meshes.clear()


func _on_effect_resolved(card: CardDefinition, affected_hexes: Array[Vector2i], operations: Array[Dictionary], chosen_steps: Array[Vector2i]) -> void:
	var applied_count: int = _apply_operations(operations, chosen_steps)
	_spend_elements(card)
	_targeting_controller.set_player_elements(_player_elements)
	if _demo_hud != null:
		_demo_hud.set_element_pool_text(_player_elements)
		_demo_hud.set_selected_card(null)
		_demo_hud.set_targeting_progress([], 0)
		_demo_hud.set_resolution_text("Resolved %s: %d ops over %d hexes" % [card.get_title(), applied_count, affected_hexes.size()])
	print("[CardDemo] Resolved card: %s" % card.card_id)
	print("[CardDemo] Steps: %s | Affected: %s" % [chosen_steps, affected_hexes])
	print("[CardDemo] Applied %d operations" % applied_count)


func _spend_elements(card: CardDefinition) -> void:
	if card == null:
		return
	for cost_entry: ElementCostEntry in card.element_costs:
		if cost_entry == null or cost_entry.amount <= 0:
			continue
		var current: int = _player_elements.get(cost_entry.element_type, 0)
		_player_elements[cost_entry.element_type] = maxi(0, current - cost_entry.amount)


func _apply_operations(operations: Array[Dictionary], chosen_steps: Array[Vector2i]) -> int:
	var applied_count: int = 0
	for operation: Dictionary in operations:
		var op_name: String = String(operation.get("operation", ""))
		match op_name:
			"terrain_height_delta":
				if _apply_terrain_height_delta(operation):
					applied_count += 1
			"terrain_state_apply":
				if _apply_terrain_state(operation):
					applied_count += 1
			"biome_convert":
				if _apply_biome_convert(operation):
					applied_count += 1
			"unit_displace":
				applied_count += _apply_unit_displace(operation, chosen_steps)
			_:
				continue
	return applied_count


func _apply_terrain_height_delta(operation: Dictionary) -> bool:
	var hex_variant: Variant = operation.get("hex", null)
	if not (hex_variant is Vector2i):
		return false
	var hex: Vector2i = hex_variant
	if not _hex_tile_index.has(hex):
		return false

	var old_height: int = _runtime_heights.get(hex, 0)
	var delta_height: int = int(operation.get("delta_height", 0))
	var min_height: int = int(operation.get("clamp_min_height", 0))
	var max_height: int = int(operation.get("clamp_max_height", 5))
	var forbid_edges: bool = bool(operation.get("forbid_height_0_and_5", false))
	var new_height: int = clampi(old_height + delta_height, min_height, max_height)
	if forbid_edges and (new_height == 0 or new_height == 5):
		return false

	_runtime_heights[hex] = new_height
	var tile_root := _hex_tile_index.get(hex, null) as Node3D
	if tile_root == null:
		return false

	var coord_variant: Variant = tile_root.get_meta("coord_h", Vector4.ZERO)
	if coord_variant is Vector4:
		var coord_h: Vector4 = coord_variant
		coord_h.w = float(new_height)
		tile_root.set_meta("coord_h", coord_h)
		var collision_body := tile_root.get_node_or_null("CollisionBody") as StaticBody3D
		if collision_body != null:
			collision_body.set_meta("coord_h", coord_h)

	tile_root.position.y = base_y + float(new_height) * height_step
	var mesh := _get_tile_mesh(tile_root)
	if mesh != null:
		var mesh_height: float = max(tile_thickness, float(new_height) * height_step)
		mesh.mesh = _visual_core.build_hex_mesh(mesh_height)
		mesh.position.y = mesh_height * 0.5

	_sync_hex_api_tile_runtime(hex)
	_refresh_tile_visual(hex)
	return true


func _apply_terrain_state(operation: Dictionary) -> bool:
	var hex_variant: Variant = operation.get("hex", null)
	if not (hex_variant is Vector2i):
		return false
	var hex: Vector2i = hex_variant
	if not _hex_tile_index.has(hex):
		return false

	var state_name: String = String(operation.get("state_name", "Normal"))
	var duration_turns: int = int(operation.get("duration_turns", 1))
	_runtime_states[hex] = {
		"state_name": state_name,
		"duration_turns": duration_turns,
	}
	var tile_root := _hex_tile_index.get(hex, null) as Node3D
	if tile_root != null:
		tile_root.set_meta("terrain_state", state_name)

	if has_node("/root/EventBus"):
		var event_bus: EventBus = get_node("/root/EventBus")
		event_bus.terrain_state_applied.emit(hex.x, hex.y, state_name)

	_refresh_tile_visual(hex)
	return true


func _apply_biome_convert(operation: Dictionary) -> bool:
	var hex_variant: Variant = operation.get("hex", null)
	if not (hex_variant is Vector2i):
		return false
	var hex: Vector2i = hex_variant
	if not _hex_tile_index.has(hex):
		return false

	var current_biome: int = _runtime_biomes.get(hex, HexGridAPI.Biome.PLAIN)
	var from_biome: int = _biome_name_to_enum(String(operation.get("from_biome_name", "")))
	var to_biome: int = _biome_name_to_enum(String(operation.get("to_biome_name", "")))
	var alt_from_biome: int = _biome_name_to_enum(String(operation.get("alternate_from_biome_name", "")))
	var alt_to_biome: int = _biome_name_to_enum(String(operation.get("alternate_to_biome_name", "")))

	if current_biome == from_biome:
		_runtime_biomes[hex] = to_biome
	elif current_biome == alt_from_biome:
		_runtime_biomes[hex] = alt_to_biome
	else:
		return false

	var tile_root := _hex_tile_index.get(hex, null) as Node3D
	if tile_root != null:
		tile_root.set_meta("biome", _runtime_biomes[hex])

	_sync_hex_api_tile_runtime(hex)
	_refresh_tile_visual(hex)
	return true


func _apply_unit_displace(operation: Dictionary, chosen_steps: Array[Vector2i]) -> int:
	var hex_variant: Variant = operation.get("hex", null)
	if not (hex_variant is Vector2i):
		return 0
	var source_hex: Vector2i = hex_variant
	var units: Array[Node] = _find_units_at_hex(source_hex)
	if units.is_empty():
		return 0

	var moved_count: int = 0
	for unit: Node in units:
		var current_hex: Vector2i = _read_unit_hex_coord(unit)
		var direction: Vector2i = _resolve_displacement_direction(source_hex, current_hex, chosen_steps)
		var target_hex: Vector2i = current_hex
		var distance: int = int(operation.get("displacement_distance", 1))
		var ignore_height: bool = bool(operation.get("ignore_height_restrictions", true))

		for _step: int in range(maxi(distance, 0)):
			var next_hex: Vector2i = target_hex + direction
			if not _hex_tile_index.has(next_hex):
				break
			if not ignore_height and not _can_unit_step_between(target_hex, next_hex):
				break
			target_hex = next_hex

		if target_hex == current_hex:
			continue
		_write_unit_hex_coord(unit, target_hex)
		moved_count += 1

	return moved_count


func _find_units_at_hex(hex: Vector2i) -> Array[Node]:
	var found: Array[Node] = []
	if get_tree() == null:
		return found
	var units: Array[Node] = get_tree().get_nodes_in_group("hex_units")
	for unit: Node in units:
		if _read_unit_hex_coord(unit) == hex:
			found.append(unit)
	return found


func _read_unit_hex_coord(unit: Node) -> Vector2i:
	if unit == null:
		return Vector2i(99999, 99999)
	if unit.has_method("get_hex_coord"):
		var coord_variant: Variant = unit.call("get_hex_coord")
		if coord_variant is Vector2i:
			return coord_variant
	var meta_coord: Variant = unit.get_meta("hex_coord", Vector2i(99999, 99999))
	if meta_coord is Vector2i:
		return meta_coord
	return Vector2i(99999, 99999)


func _write_unit_hex_coord(unit: Node, hex: Vector2i) -> void:
	if unit == null:
		return
	if unit.has_method("set_hex_coord"):
		unit.call("set_hex_coord", hex)
	unit.set_meta("hex_coord", hex)
	if unit is Node3D:
		var tile_root := _hex_tile_index.get(hex, null) as Node3D
		if tile_root != null:
			var unit_3d := unit as Node3D
			unit_3d.global_position = tile_root.global_position + Vector3(0.0, tile_thickness + 0.2, 0.0)


func _resolve_displacement_direction(source_hex: Vector2i, current_hex: Vector2i, chosen_steps: Array[Vector2i]) -> Vector2i:
	if chosen_steps.size() >= 2:
		return CardHexMath.nearest_direction(chosen_steps[0], chosen_steps[1])
	if chosen_steps.size() == 1:
		if current_hex == chosen_steps[0]:
			return CardHexMath.nearest_direction(source_hex, current_hex + Vector2i(1, 0))
		return CardHexMath.nearest_direction(chosen_steps[0], current_hex)
	if source_hex == current_hex:
		return Vector2i(1, 0)
	return CardHexMath.nearest_direction(source_hex, current_hex)


func _can_unit_step_between(from_hex: Vector2i, to_hex: Vector2i) -> bool:
	var from_height: int = _runtime_heights.get(from_hex, 0)
	var to_height: int = _runtime_heights.get(to_hex, 0)
	return absi(to_height - from_height) <= 1


func _sync_hex_api_tile_runtime(hex: Vector2i) -> void:
	if not has_node("/root/HexGridAPI"):
		return
	var api: HexGridAPI = get_node("/root/HexGridAPI")
	var tile: HexGridTileData = api.get_tile(hex.x, hex.y)
	if tile == null:
		return
	tile.height = _runtime_heights.get(hex, tile.height)
	tile.biome = _runtime_biomes.get(hex, tile.biome)
	tile.biome_name = api.biome_to_string(tile.biome)
	tile.coord_h.w = float(tile.height)


func _refresh_tile_visual(hex: Vector2i) -> void:
	var tile_root := _hex_tile_index.get(hex, null) as Node3D
	if tile_root == null:
		return
	var mesh := _get_tile_mesh(tile_root)
	if mesh == null:
		return

	var biome: int = _runtime_biomes.get(hex, HexGridAPI.Biome.PLAIN)
	var material: StandardMaterial3D = _visual_core.build_biome_material(biome)
	if _runtime_states.has(hex):
		var state_data: Dictionary = _runtime_states[hex]
		var state_name: String = String(state_data.get("state_name", ""))
		material.albedo_color = material.albedo_color.lerp(_state_tint_for_name(state_name), 0.45)
		material.emission_enabled = true
		material.emission = _state_tint_for_name(state_name) * 0.4
	mesh.material_override = material


func _get_tile_mesh(tile_root: Node3D) -> MeshInstance3D:
	for child: Node in tile_root.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null:
			return mesh
	return null


func _state_tint_for_name(state_name: String) -> Color:
	match state_name.to_lower():
		"on fire":
			return Color(0.95, 0.33, 0.15)
		"frozen":
			return Color(0.55, 0.78, 1.0)
		"muddy":
			return Color(0.45, 0.29, 0.18)
		"mist":
			return Color(0.82, 0.84, 0.9)
		"chasm":
			return Color(0.12, 0.12, 0.16)
		_:
			return Color(0.7, 0.7, 0.7)


func _biome_name_to_enum(biome_name: String) -> int:
	match biome_name.to_lower():
		"water":
			return HexGridAPI.Biome.WATER
		"desert":
			return HexGridAPI.Biome.DESERT
		"plain":
			return HexGridAPI.Biome.PLAIN
		"forest":
			return HexGridAPI.Biome.FOREST
		"rocky":
			return HexGridAPI.Biome.ROCKY
		"mountain peak":
			return HexGridAPI.Biome.MOUNTAIN_PEAK
		_:
			return HexGridAPI.Biome.PLAIN
