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

var _tiles_ordered: Array[HexGridTileData] = []


# Stores externally generated tiles and emits the standard grid signals.
func set_tiles(tiles: Array[HexGridTileData]) -> void:
	_tiles_ordered = tiles
	_emit_grid_generated()


# Returns the most recently generated tile array.
func get_all_tiles() -> Array[HexGridTileData]:
	return _tiles_ordered


# Returns true when a tile exists at the requested axial coordinate.
func has_tile(q: int, r: int) -> bool:
	return get_tile(q, r) != null


# Finds the tile for an axial coordinate by scanning the cached tile list.
func get_tile(q: int, r: int) -> HexGridTileData:
	for tile in _tiles_ordered:
		if int(tile.coord_h.x) == q and int(tile.coord_h.y) == r:
			return tile
	return null


# Returns the stored coord_h vector for a tile, or Vector4.ZERO when missing.
func get_coord_h(q: int, r: int) -> Vector4:
	var tile := get_tile(q, r)
	if tile == null:
		return Vector4.ZERO
	return tile.coord_h


# Returns the height at an axial coordinate, or -1 when no tile exists.
func get_height_at(q: int, r: int) -> int:
	var tile := get_tile(q, r)
	if tile == null:
		return -1
	return tile.height


# Returns the biome at an axial coordinate, or -1 when no tile exists.
func get_biome_at(q: int, r: int) -> int:
	var tile := get_tile(q, r)
	if tile == null:
		return -1
	return tile.biome


# Returns the cached world position for a tile, or Vector3.ZERO when missing.
func get_world_position(q: int, r: int) -> Vector3:
	var tile := get_tile(q, r)
	if tile == null:
		return Vector3.ZERO
	return tile.world_position


# Maps a biome enum value to a readable display string.
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


# Emits the local and global grid-generated signals for the current tile cache.
func _emit_grid_generated() -> void:
	grid_generated.emit(_tiles_ordered.size())
	if has_node("/root/EventBus"):
		var event_bus: EventBus = get_node("/root/EventBus")
		event_bus.hex_grid_generated.emit(_tiles_ordered.size())
