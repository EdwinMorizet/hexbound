class_name HexGridTileData
extends RefCounted

@export_group("Coordinates")
## Axial coordinates stored as q, r, s, and height.
@export var coord_h: Vector4 = Vector4.ZERO
## World-space position of the tile root.
@export var world_position: Vector3 = Vector3.ZERO

@export_group("Terrain")
## Biome type of the tile.
@export_enum("Water", "Desert", "Plain", "Forest", "Rocky", "Mountain Peak") var biome: int = 0
## Height level from 0 to 5.
@export_range(0, 5, 1) var height: int = 0
## Moisture sample used to resolve biome.
@export_range(-1.0, 1.0, 0.001) var moisture: float = 0.0

@export_group("Display")
## Human-readable biome label.
@export var biome_name: String = ""