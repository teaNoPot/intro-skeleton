class_name LowPoly
## Small helpers for building placeholder geometry with a flat, low-poly look.

static var _mats := {}


## One shared material per color, so hundreds of boxes stay cheap.
static func mat(color: Color, emission := 0.0) -> StandardMaterial3D:
	var key := color.to_html() + str(emission)
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


## Recompute normals per face so round primitives look faceted instead of smooth.
static func flat(mesh: Mesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.deindex()
	st.generate_normals()
	return st.commit()


static func add_mesh(mesh: Mesh, color: Color, parent: Node3D, pos := Vector3.ZERO, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, emission)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func box(size: Vector3, color: Color, parent: Node3D, pos := Vector3.ZERO, emission := 0.0) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return add_mesh(bm, color, parent, pos, emission)


## A box you can bump into (and that the navigation mesh walks around).
static func solid_box(size: Vector3, color: Color, parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	box(size, color, body)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	return body


static func cylinder(radius: float, height: float, sides: int, color: Color, parent: Node3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = sides
	cm.rings = 1
	return add_mesh(flat(cm), color, parent, pos)


static func blob(radius: float, color: Color, parent: Node3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 1.8
	sm.radial_segments = 7
	sm.rings = 4
	return add_mesh(flat(sm), color, parent, pos)
