extends Node3D
## Builds a placeholder town out of boxes so the game is playable before you have
## any models. When you start placing real buildings, untick `enabled` (or delete
## this node) and put your own stuff under NavigationRegion3D instead.

@export var enabled := true
@export var blocks := Vector2i(4, 4)
@export var block_size := 24.0
@export var road_width := 9.0
@export var sidewalk_width := 2.2
@export var random_seed := 7

const WALLS := ["f2e8cf", "e9c46a", "f4a261", "e76f51", "a8dadc", "bde0fe", "cdb4db", "b7e4c7", "ffd6a5", "d4a373"]
const CARS := ["d62828", "f77f00", "fcbf49", "2a9d8f", "457b9d", "f1faee", "1d3557", "6a4c93"]

var _rng := RandomNumberGenerator.new()
var _windows: Array[Transform3D] = []
var _window_mat: StandardMaterial3D
var _spawn := Vector3.ZERO


func _ready() -> void:
	add_to_group("night_aware")


## Called by main.gd before the navigation mesh is baked.
func build() -> void:
	if not enabled:
		return
	_rng.seed = random_seed
	for c in get_children():
		c.queue_free()
	_windows.clear()
	_window_mat = StandardMaterial3D.new()
	_window_mat.albedo_color = Color("2e3a4f")
	_window_mat.roughness = 0.2
	_window_mat.emission = Color("ffd98a")
	_window_mat.emission_enabled = true
	_window_mat.emission_energy_multiplier = 0.0

	var cell := block_size + road_width
	var total := Vector2(blocks.x * cell + road_width, blocks.y * cell + road_width)
	var origin := Vector3(-total.x * 0.5, 0, -total.y * 0.5)
	# asphalt under the whole grid
	LowPoly.box(Vector3(total.x, 0.04, total.y), Color("4a4e57"), self, origin + Vector3(total.x * 0.5, 0.02, total.y * 0.5))
	for bx in blocks.x:
		for bz in blocks.y:
			var lo := origin + Vector3(road_width + bx * cell, 0, road_width + bz * cell)
			_build_block(lo)
	_build_road_lines(origin, total, cell)
	# spawn on the sidewalk next to a crossroads in the middle of town
	_spawn = origin + Vector3(road_width * 0.5 + cell * (blocks.x / 2) + road_width * 0.5 + 1.0, 0.1, road_width * 0.5 + cell * (blocks.y / 2) + road_width * 0.5 + 6.0)
	_build_windows()


func spawn_point() -> Vector3:
	return _spawn


func set_night(amount: float) -> void:
	if _window_mat:
		_window_mat.emission_energy_multiplier = amount * 1.6


func _build_block(lo: Vector3) -> void:
	var s := block_size
	var center := lo + Vector3(s * 0.5, 0, s * 0.5)
	LowPoly.box(Vector3(s, 0.08, s), Color("b8b8b0"), self, center + Vector3(0, 0.04, 0))
	var inner := s - sidewalk_width * 2.0
	LowPoly.box(Vector3(inner, 0.1, inner), Color("7fb069"), self, center + Vector3(0, 0.05, 0))
	# four lots per block, most of them with a building
	var lot := inner * 0.5
	for ix in 2:
		for iz in 2:
			var lot_center := lo + Vector3(sidewalk_width + lot * (ix + 0.5), 0, sidewalk_width + lot * (iz + 0.5))
			var r := _rng.randf()
			if r < 0.78:
				_building(lot_center, lot, Vector2(ix * 2 - 1, iz * 2 - 1))
			elif r < 0.9:
				_tree(lot_center + Vector3(_rng.randf_range(-2, 2), 0, _rng.randf_range(-2, 2)))
				_tree(lot_center + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3)))
	# street lights on the corners, trees and benches along the sidewalk
	for c in [Vector3(0, 0, 0), Vector3(s, 0, 0), Vector3(0, 0, s), Vector3(s, 0, s)]:
		var inset := Vector3(0.6 if c.x == 0 else -0.6, 0, 0.6 if c.z == 0 else -0.6)
		_street_light(lo + c + inset)
	for i in 3:
		var t := (i + 1) / 4.0
		if _rng.randf() < 0.6:
			_tree(lo + Vector3(s * t, 0, 1.0))
		if _rng.randf() < 0.3:
			_bench(lo + Vector3(1.0, 0, s * t))
		if _rng.randf() < 0.5:
			_car(lo + Vector3(s * t, 0, -1.8), 0.0)
		if _rng.randf() < 0.3:
			_trash_can(lo + Vector3(s - 1.0, 0, s * t))


func _building(c: Vector3, lot: float, outward: Vector2) -> void:
	var w := _rng.randf_range(lot * 0.62, lot * 0.9)
	var d := _rng.randf_range(lot * 0.62, lot * 0.9)
	var floors := _rng.randi_range(1, 4)
	var h := 3.2 * floors + 0.4
	var wall := Color(WALLS[_rng.randi() % WALLS.size()])
	# nudge the building toward the street side of its lot
	var pos := c + Vector3(outward.x * (lot - w) * 0.35, h * 0.5, outward.y * (lot - d) * 0.35)
	LowPoly.solid_box(Vector3(w, h, d), wall, self, pos)
	LowPoly.box(Vector3(w + 0.3, 0.3, d + 0.3), wall.darkened(0.25), self, pos + Vector3(0, h * 0.5 + 0.15, 0))
	if _rng.randf() < 0.5:
		LowPoly.box(Vector3(1.4, 1.0, 1.4), Color("9aa0a6"), self, pos + Vector3(w * 0.2, h * 0.5 + 0.8, -d * 0.15))
	# windows on all four sides (drawn later as one MultiMesh, so they're nearly free)
	for side in 4:
		var along := w if side % 2 == 0 else d
		var normal := [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)][side] as Vector3
		var tangent := Vector3(normal.z, 0, -normal.x)
		var half := (d if side % 2 == 0 else w) * 0.5 + 0.02
		var count := int(along / 2.4)
		for f in floors:
			for i in count:
				var off := (i - (count - 1) * 0.5) * 2.4
				var p := pos + normal * half + tangent * off + Vector3(0, -h * 0.5 + 1.7 + f * 3.2, 0)
				if f == 0 and i == count / 2:
					var door := Vector3(1.1, 2.1, 0.1) if side % 2 == 0 else Vector3(0.1, 2.1, 1.1)
					LowPoly.box(door, Color("5c4033"), self, pos + normal * half + tangent * off + Vector3(0, -h * 0.5 + 1.05, 0))
					continue
				var xf := Transform3D(Basis.looking_at(-normal) * Basis.from_scale(Vector3(1.1, 1.3, 0.08)), p)
				_windows.append(xf)


func _build_windows() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = _windows.size()
	for i in _windows.size():
		mm.set_instance_transform(i, _windows[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _window_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _build_road_lines(origin: Vector3, total: Vector2, cell: float) -> void:
	var dash := BoxMesh.new()
	dash.size = Vector3(0.18, 0.02, 1.6)
	var xfs: Array[Transform3D] = []
	for i in blocks.x + 1:
		var x := origin.x + road_width * 0.5 + i * cell
		var z := origin.z + 2.0
		while z < origin.z + total.y - 2.0:
			xfs.append(Transform3D(Basis(), Vector3(x, 0.05, z)))
			z += 4.0
	for i in blocks.y + 1:
		var z := origin.z + road_width * 0.5 + i * cell
		var x := origin.x + 2.0
		while x < origin.x + total.x - 2.0:
			xfs.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(x, 0.05, z)))
			x += 4.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = dash
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = LowPoly.mat(Color("f1e9d2"))
	add_child(mmi)


func _street_light(p: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p
	add_child(body)
	LowPoly.cylinder(0.08, 5.0, 6, Color("3a3f47"), body, Vector3(0, 2.5, 0))
	LowPoly.box(Vector3(0.12, 0.1, 1.0), Color("3a3f47"), body, Vector3(0, 4.95, 0.4))
	LowPoly.box(Vector3(0.35, 0.15, 0.5), Color("fff1c1"), body, Vector3(0, 4.85, 0.8), 2.0)
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.12
	cs.height = 5.0
	shape.shape = cs
	shape.position.y = 2.5
	body.add_child(shape)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 4.5, 0.8)
	light.light_color = Color("ffcf87")
	light.light_energy = 2.2
	light.omni_range = 11.0
	light.visible = false
	light.add_to_group("streetlights")
	body.add_child(light)


func _tree(p: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p
	add_child(body)
	LowPoly.cylinder(0.16, 2.0, 5, Color("6b4a33"), body, Vector3(0, 1.0, 0))
	var green := Color(["5a9b48", "6fb05a", "4d8a41", "86b85c"][_rng.randi() % 4])
	LowPoly.blob(1.5, green, body, Vector3(0, 2.8, 0))
	LowPoly.blob(1.0, green.lightened(0.08), body, Vector3(0.4, 3.7, 0.2))
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.25
	cs.height = 2.0
	shape.shape = cs
	shape.position.y = 1.0
	body.add_child(shape)


func _bench(p: Vector3) -> void:
	var body := LowPoly.solid_box(Vector3(0.6, 0.45, 1.8), Color("8c5a3c"), self, p + Vector3(0, 0.225, 0))
	LowPoly.box(Vector3(0.1, 0.5, 1.8), Color("8c5a3c"), body, Vector3(-0.28, 0.45, 0))


func _trash_can(p: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p
	add_child(body)
	LowPoly.cylinder(0.3, 0.9, 7, Color("3f6e4f"), body, Vector3(0, 0.45, 0))
	LowPoly.cylinder(0.33, 0.08, 7, Color("2f5a3f"), body, Vector3(0, 0.93, 0))
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.3
	cs.height = 0.9
	shape.shape = cs
	shape.position.y = 0.45
	body.add_child(shape)


func _car(p: Vector3, yaw: float) -> void:
	var color := Color(CARS[_rng.randi() % CARS.size()])
	var body := LowPoly.solid_box(Vector3(4.2, 0.8, 1.9), color, self, p + Vector3(0, 0.7, 0))
	body.rotation.y = yaw
	LowPoly.box(Vector3(2.2, 0.7, 1.7), color.lightened(0.1), body, Vector3(-0.2, 0.75, 0))
	LowPoly.box(Vector3(2.0, 0.55, 1.72), Color("2e3a4f"), body, Vector3(-0.2, 0.75, 0))
	for sx in [-1.3, 1.3]:
		for sz in [-0.95, 0.95]:
			var wheel := LowPoly.cylinder(0.36, 0.25, 8, Color("1f1f1f"), body, Vector3(sx, -0.35, sz))
			wheel.rotation.x = PI * 0.5
	LowPoly.box(Vector3(0.05, 0.2, 0.4), Color("fff1c1"), body, Vector3(-2.12, 0.1, 0.6), 1.0)
	LowPoly.box(Vector3(0.05, 0.2, 0.4), Color("fff1c1"), body, Vector3(-2.12, 0.1, -0.6), 1.0)
