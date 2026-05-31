class_name HexGridGenerationSettings
extends RefCounted

@export_group("Grid")
## The hex map side length in tiles.
@export_range(2, 16, 1) var side_length: int = 5
## Seed used for deterministic generation.
@export_range(-2147483648, 2147483647, 1) var seed: int = 1337

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
@export_range(0.01, 100.0, 0.01) var tile_radius: float = 1.0
## Vertical step between tile height levels.
@export_range(0.01, 10.0, 0.01) var height_step: float = 0.3