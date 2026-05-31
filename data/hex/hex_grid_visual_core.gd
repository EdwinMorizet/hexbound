class_name HexGridVisualCore
extends RefCounted

var tile_radius: float = 1.0
var tile_thickness: float = 0.25


func build_hex_mesh(height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = tile_radius
	mesh.bottom_radius = tile_radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh



func build_collider_shape(mesh: Mesh) -> Shape3D:
	if mesh == null:
		return null
	var shape := mesh.create_convex_shape()
	if shape != null:
		return shape
	return mesh.create_trimesh_shape()


func build_biome_material(biome: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = biome_color(biome)
	material.roughness = 0.85
	material.metallic = 0.0
	return material


func biome_color(biome: int) -> Color:
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