extends Node

signal grid_generated(tile_count: int)

enum Biome {
	WATER,
	DESERT,
	PLAIN,
	FOREST,
	ROCKY,
	MOUNTAIN_PEAK,
}

@export_group("Grid")
## The hex map side length in tiles.
@export_range(2, 16, 1) var side_length: int = 5
## Seed used for deterministic generation.
@export_range(-2147483648, 2147483647, 1) var map_seed: int = 1337

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

@export_group("Geometry")
## Hex radius used for world-space placement.
@export var tile_radius: float = 1.0
## Vertical step between tile height levels.
@export_range(0.01, 10.0, 0.01) var height_step: float = 0.3

var _tiles_ordered: Array[HexGridTileData] = []
var _generation_core: HexGridGenerationCore = HexGridGenerationCore.new()


func _ready() -> void:
	generate_grid()


func configure(settings: HexGridGenerationSettings) -> void:
	if settings == null:
		return
	_generation_core.configure(settings)
	_sync_exports_from_core()


func generate_grid(settings: HexGridGenerationSettings = null) -> Array[HexGridTileData]:
	if settings != null:
		_generation_core.configure(settings)
		_sync_exports_from_core()
	else:
		_sync_core_from_exports()

	_tiles_ordered = _generation_core.generate_grid()

	grid_generated.emit(_tiles_ordered.size())
	return _tiles_ordered


func get_all_tiles() -> Array[HexGridTileData]:
	return _tiles_ordered


func has_tile(q: int, r: int) -> bool:
	return get_tile(q, r) != null


func get_tile(q: int, r: int) -> HexGridTileData:
	for tile in _tiles_ordered:
		if int(tile.coord_h.x) == q and int(tile.coord_h.y) == r:
			return tile
	return null


func get_coord_h(q: int, r: int) -> Vector4:
	var tile := get_tile(q, r)
	if tile == null:
		return Vector4.ZERO
	return tile.coord_h


func get_height_at(q: int, r: int) -> int:
	var tile := get_tile(q, r)
	if tile == null:
		return -1
	return tile.height


func get_biome_at(q: int, r: int) -> int:
	var tile := get_tile(q, r)
	if tile == null:
		return -1
	return tile.biome


func get_world_position(q: int, r: int) -> Vector3:
	var tile := get_tile(q, r)
	if tile == null:
		return Vector3.ZERO
	return tile.world_position


func axial_to_world(q: int, r: int, height: int = 0) -> Vector3:
	return _generation_core.axial_to_world(q, r, height)


func biome_to_string(biome: int) -> String:
	match biome:
		Biome.WATER:
			return "Water"
		Biome.DESERT:
			return "Desert"
		Biome.PLAIN:
			return "Plain"
		Biome.FOREST:
			return "Forest"
		Biome.ROCKY:
			return "Rocky"
		Biome.MOUNTAIN_PEAK:
			return "Mountain Peak"
		_:
			return "Unknown"



func _sync_core_from_exports() -> void:
	_generation_core.side_length = side_length
	_generation_core.map_seed = map_seed
	_generation_core.elevation_frequency = elevation_frequency
	_generation_core.elevation_octaves = elevation_octaves
	_generation_core.moisture_frequency = moisture_frequency
	_generation_core.moisture_octaves = moisture_octaves
	_generation_core.desert_moisture_threshold = desert_moisture_threshold
	_generation_core.forest_moisture_threshold = forest_moisture_threshold
	_generation_core.tile_radius = tile_radius
	_generation_core.height_step = height_step


func _sync_exports_from_core() -> void:
	side_length = _generation_core.side_length
	map_seed = _generation_core.map_seed
	elevation_frequency = _generation_core.elevation_frequency
	elevation_octaves = _generation_core.elevation_octaves
	moisture_frequency = _generation_core.moisture_frequency
	moisture_octaves = _generation_core.moisture_octaves
	desert_moisture_threshold = _generation_core.desert_moisture_threshold
	forest_moisture_threshold = _generation_core.forest_moisture_threshold
	tile_radius = _generation_core.tile_radius
	height_step = _generation_core.height_step
