class_name CardHexMath
extends RefCounted

const AXIAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


static func axial_distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	var ds := -dq - dr
	return int((abs(dq) + abs(dr) + abs(ds)) / 2)


static func nearest_direction(from_hex: Vector2i, to_hex: Vector2i) -> Vector2i:
	if from_hex == to_hex:
		return AXIAL_DIRECTIONS[0]
	var best_direction := AXIAL_DIRECTIONS[0]
	var best_distance := axial_distance(from_hex + best_direction, to_hex)
	for direction: Vector2i in AXIAL_DIRECTIONS:
		var candidate_distance := axial_distance(from_hex + direction, to_hex)
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			best_direction = direction
	return best_direction


static func direction_perpendiculars(direction: Vector2i) -> Array[Vector2i]:
	var direction_index := AXIAL_DIRECTIONS.find(direction)
	if direction_index == -1:
		return [AXIAL_DIRECTIONS[1], AXIAL_DIRECTIONS[5]]
	var left_index := posmod(direction_index + 1, AXIAL_DIRECTIONS.size())
	var right_index := posmod(direction_index - 1, AXIAL_DIRECTIONS.size())
	return [AXIAL_DIRECTIONS[left_index], AXIAL_DIRECTIONS[right_index]]


static func hex_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var distance := axial_distance(a, b)
	if distance == 0:
		return [a]

	var results: Array[Vector2i] = []
	for i: int in range(distance + 1):
		var t := float(i) / float(distance)
		var cube := _cube_lerp(_axial_to_cube(a), _axial_to_cube(b), t)
		results.append(_cube_to_axial(_cube_round(cube)))
	return unique_hexes(results)


static func hex_disc(center: Vector2i, radius: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for dq: int in range(-radius, radius + 1):
		var r_min := maxi(-radius, -dq - radius)
		var r_max := mini(radius, -dq + radius)
		for dr: int in range(r_min, r_max + 1):
			results.append(Vector2i(center.x + dq, center.y + dr))
	return unique_hexes(results)


static func hex_disc_mask(center: Vector2i, outer_radius: int, inner_radius: int) -> Array[Vector2i]:
	var outer := hex_disc(center, maxi(0, outer_radius))
	if inner_radius <= 0:
		return outer

	var inner := hex_disc(center, inner_radius)
	var inner_set: Dictionary[Vector2i, bool] = {}
	for hex: Vector2i in inner:
		inner_set[hex] = true

	var masked: Array[Vector2i] = []
	for hex: Vector2i in outer:
		if not inner_set.has(hex):
			masked.append(hex)
	return masked


static func unique_hexes(hexes: Array[Vector2i]) -> Array[Vector2i]:
	var seen: Dictionary[Vector2i, bool] = {}
	var unique: Array[Vector2i] = []
	for hex: Vector2i in hexes:
		if seen.has(hex):
			continue
		seen[hex] = true
		unique.append(hex)
	return unique


static func _axial_to_cube(hex: Vector2i) -> Vector3:
	return Vector3(float(hex.x), float(hex.y), float(-hex.x - hex.y))


static func _cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.y)


static func _cube_lerp(a: Vector3, b: Vector3, t: float) -> Vector3:
	return Vector3(
		lerpf(a.x, b.x, t),
		lerpf(a.y, b.y, t),
		lerpf(a.z, b.z, t)
	)


static func _cube_round(cube: Vector3) -> Vector3i:
	var rx := roundi(cube.x)
	var ry := roundi(cube.y)
	var rz := roundi(cube.z)

	var x_diff: float = absf(float(rx) - cube.x)
	var y_diff: float = absf(float(ry) - cube.y)
	var z_diff: float = absf(float(rz) - cube.z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector3i(rx, ry, rz)
