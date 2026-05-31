class_name HexGridGenerationCore
extends RefCounted

var side_length: int = 5
var map_seed: int = 1337
var elevation_frequency: float = 0.09
var elevation_octaves: int = 4
var moisture_frequency: float = 0.12
var moisture_octaves: int = 3
var desert_moisture_threshold: float = -0.05
var forest_moisture_threshold: float = 0.18
var tile_radius: float = 1.0
var height_step: float = 0.3

var _elevation_noise: FastNoiseLite = FastNoiseLite.new()
var _moisture_noise: FastNoiseLite = FastNoiseLite.new()


func configure(settings: HexGridGenerationSettings) -> void:
	if settings == null:
		return
	side_length = max(2, int(settings.side_length))
	map_seed = int(settings.map_seed)
	elevation_frequency = max(0.001, float(settings.elevation_frequency))
	elevation_octaves = maxi(1, int(settings.elevation_octaves))
	moisture_frequency = max(0.001, float(settings.moisture_frequency))
	moisture_octaves = maxi(1, int(settings.moisture_octaves))
	desert_moisture_threshold = clampf(float(settings.desert_moisture_threshold), -1.0, 1.0)
	forest_moisture_threshold = clampf(float(settings.forest_moisture_threshold), -1.0, 1.0)
	tile_radius = max(0.05, float(settings.tile_radius))
	height_step = max(0.01, float(settings.height_step))


func generate_grid(settings: HexGridGenerationSettings = null) -> Array[HexGridTileData]:
	if settings != null:
		configure(settings)

	_configure_noise()
	var tiles: Array[HexGridTileData] = []
	var radius := side_length - 1
	for q in range(-radius, radius + 1):
		var r_min := maxi(-radius, -q - radius)
		var r_max := mini(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			var s := -q - r
			var elevation_value := _elevation_noise.get_noise_2d(float(q), float(r))
			var moisture_value := _moisture_noise.get_noise_2d(float(q), float(r))
			var height := _noise_to_height(elevation_value)
			var biome := _resolve_biome(height, moisture_value)
			var tile := HexGridTileData.new()
			tile.coord_h = Vector4(float(q), float(r), float(s), float(height))
			tile.biome = biome
			tile.biome_name = biome_to_string(biome)
			tile.height = height
			tile.moisture = moisture_value
			tile.world_position = axial_to_world(q, r, height)
			tiles.append(tile)
	return tiles


func axial_to_world(q: int, r: int, height: int = 0) -> Vector3:
	var x := tile_radius * 1.5 * float(q)
	var z := tile_radius * sqrt(3.0) * (float(r) + float(q) * 0.5)
	var y := float(height) * height_step * 0.5
	return Vector3(x, y, z)


func biome_to_string(biome: int) -> String:
	match biome:
		HexGridAPI.Biome.WATER:
			return "Water"
		HexGridAPI.Biome.DESERT:
			return "Desert"
		HexGridAPI.Biome.PLAIN:
			return "Plain"
		HexGridAPI.Biome.FOREST:
			return "Forest"
		HexGridAPI.Biome.ROCKY:
			return "Rocky"
		HexGridAPI.Biome.MOUNTAIN_PEAK:
			return "Mountain Peak"
		_:
			return "Unknown"


func _configure_noise() -> void:
	_elevation_noise.seed = map_seed
	_elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_elevation_noise.frequency = elevation_frequency
	_elevation_noise.fractal_octaves = elevation_octaves
	_elevation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

	_moisture_noise.seed = map_seed + 1013
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.frequency = moisture_frequency
	_moisture_noise.fractal_octaves = moisture_octaves
	_moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM


func _noise_to_height(noise_value: float) -> int:
	var normalized := (noise_value + 1.0) * 0.5
	return clampi(int(floor(normalized * 6.0)), 0, 5)


func _resolve_biome(height: int, moisture: float) -> int:
	if height == 0:
		return HexGridAPI.Biome.WATER
	if height == 5:
		return HexGridAPI.Biome.MOUNTAIN_PEAK
	if height <= 2:
		if moisture < desert_moisture_threshold:
			return HexGridAPI.Biome.DESERT
		return HexGridAPI.Biome.PLAIN
	if moisture >= forest_moisture_threshold:
		return HexGridAPI.Biome.FOREST
	return HexGridAPI.Biome.ROCKY
