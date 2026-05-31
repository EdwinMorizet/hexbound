@tool
class_name HexGridGenerator3D
extends Node3D

@export_group("Behavior")
## Generates immediately when the node enters the scene tree.
@export var auto_generate_on_ready: bool = true
## Uses the autoload singleton instead of local generation logic.
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


func _ready() -> void:
	if auto_generate_on_ready:
		call_deferred("regenerate")


func regenerate() -> void:
	if clear_before_generate:
		_clear_tiles()
	var tiles := _generate_tiles()
	_render_tiles(tiles)


func _regenerate_with_new_seed() -> void:
	if Engine.is_editor_hint():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		world_seed = rng.randi()
	regenerate()


func _generate_tiles() -> Array[HexGridTileData]:
	if sync_with_autoload and has_node("/root/HexGridAPI"):
		var api = get_node("/root/HexGridAPI")
		var settings := _create_generation_settings()
		api.generate_grid(settings)
		return api.get_all_tiles()
	return _generate_tiles_local()


func _generate_tiles_local() -> Array[HexGridTileData]:
	_sync_core_from_exports()
	return _generation_core.generate_grid()


func _render_tiles(tiles: Array[HexGridTileData]) -> void:
	var root := _get_or_create_tiles_root()
	for tile in tiles:
		var coord_h: Vector4 = tile.coord_h
		var biome: int = tile.biome
		var world_position: Vector3 = tile.world_position
		var cell_height := height_step

		var tile_root := Node3D.new()
		tile_root.name = "Hex_%d_%d_%d" % [int(coord_h.x), int(coord_h.y), int(coord_h.z)]
		tile_root.position = Vector3(
			world_position.x,
			base_y + world_position.y,
			world_position.z
		)
		tile_root.set_meta("coord_h", coord_h)
		root.add_child(tile_root)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _create_hex_mesh(tile.height * height_step)
		mesh_instance.material_override = _create_biome_material(biome)
		mesh_instance.position = Vector3(0.0, cell_height * 0.5, 0.0)
		mesh_instance.rotation_degrees = Vector3(0.0, 30.0, 0.0)
		tile_root.add_child(mesh_instance)

		if generate_collision:
			_add_collision(tile_root, cell_height)

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


func _create_hex_mesh(height:float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = tile_radius
	mesh.bottom_radius = tile_radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


func _create_generation_settings() -> HexGridGenerationSettings:
	var settings := HexGridGenerationSettings.new()
	settings.side_length = side_length
	settings.map_seed = world_seed
	settings.elevation_frequency = elevation_frequency
	settings.elevation_octaves = elevation_octaves
	settings.moisture_frequency = moisture_frequency
	settings.moisture_octaves = moisture_octaves
	settings.desert_moisture_threshold = desert_moisture_threshold
	settings.forest_moisture_threshold = forest_moisture_threshold
	settings.tile_radius = tile_radius
	settings.height_step = height_step
	return settings


func _add_collision(tile_root: Node3D, cell_height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.position = Vector3(0.0, cell_height * 0.5, 0.0)

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape"

	var shape := ConvexPolygonShape3D.new()
	shape.points = _create_hex_prism_points(tile_radius, cell_height)
	collision_shape.shape = shape

	body.add_child(collision_shape)
	tile_root.add_child(body)


func _create_hex_prism_points(radius: float, thickness: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var half_h := thickness * 0.5
	for i in range(6):
		var angle := deg_to_rad(30.0 + float(i) * 60.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		points.append(Vector3(x, half_h, z))
		points.append(Vector3(x, -half_h, z))
	return points


func _create_biome_material(biome: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = _biome_color(biome)
	material.roughness = 0.85
	material.metallic = 0.0
	return material


func _biome_color(biome: int) -> Color:
	match biome:
		0:
			return Color(0.20, 0.40, 0.85)
		1:
			return Color(0.84, 0.74, 0.45)
		2:
			return Color(0.56, 0.72, 0.43)
		3:
			return Color(0.19, 0.48, 0.24)
		4:
			return Color(0.46, 0.46, 0.49)
		5:
			return Color(0.86, 0.86, 0.89)
		_:
			return Color(1.0, 0.0, 1.0)


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
