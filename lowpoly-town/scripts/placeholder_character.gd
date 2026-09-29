class_name PlaceholderCharacter
extends Node3D
## A chunky stand-in person made of boxes, with Idle, Walk, Run, Jump and Talk animations.
## CharacterModel shows this until you give it a real model.

const SKIN := [Color("f1c7a1"), Color("d9a47c"), Color("a8744f"), Color("6e4a33")]
const SHIRTS := [Color("e76f51"), Color("2a9d8f"), Color("e9c46a"), Color("457b9d"), Color("f4a261"), Color("8d99ae"), Color("6a4c93"), Color("d62828")]
const PANTS := [Color("264653"), Color("3d405b"), Color("5c4d3c"), Color("1d3557"), Color("495057")]
const HAIR := [Color("2b1d14"), Color("5a3825"), Color("c9a063"), Color("1b1b1b"), Color("8c2f1b"), Color("b0b0b0")]

## 0 picks a random look every time.
@export var look_seed := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	if look_seed != 0:
		rng.seed = look_seed
	else:
		rng.randomize()
	var skin: Color = SKIN[rng.randi() % SKIN.size()]
	var shirt: Color = SHIRTS[rng.randi() % SHIRTS.size()]
	var pants: Color = PANTS[rng.randi() % PANTS.size()]
	var hair: Color = HAIR[rng.randi() % HAIR.size()]
	var shoe := Color("2b2b2b")

	var hips := _pivot("Hips", self, Vector3(0, 0.95, 0))
	for side in [-1, 1]:
		var leg := _pivot("LegL" if side < 0 else "LegR", hips, Vector3(0.12 * side, 0, 0))
		LowPoly.box(Vector3(0.19, 0.86, 0.21), pants, leg, Vector3(0, -0.43, 0))
		LowPoly.box(Vector3(0.21, 0.12, 0.32), shoe, leg, Vector3(0, -0.89, -0.04))
	var torso := _pivot("Torso", hips, Vector3.ZERO)
	LowPoly.box(Vector3(0.52, 0.64, 0.3), shirt, torso, Vector3(0, 0.33, 0))
	for side in [-1, 1]:
		var arm := _pivot("ArmL" if side < 0 else "ArmR", torso, Vector3(0.33 * side, 0.6, 0))
		LowPoly.box(Vector3(0.14, 0.34, 0.16), shirt, arm, Vector3(0, -0.14, 0))
		LowPoly.box(Vector3(0.12, 0.3, 0.13), skin, arm, Vector3(0, -0.44, 0))
	var head := _pivot("Head", torso, Vector3(0, 0.66, 0))
	LowPoly.box(Vector3(0.38, 0.4, 0.36), skin, head, Vector3(0, 0.2, 0))
	LowPoly.box(Vector3(0.4, 0.13, 0.38), hair, head, Vector3(0, 0.43, 0.01))
	LowPoly.box(Vector3(0.4, 0.22, 0.08), hair, head, Vector3(0, 0.3, 0.17))
	for side in [-1, 1]:
		LowPoly.box(Vector3(0.06, 0.08, 0.02), Color("1b1b1b"), head, Vector3(0.085 * side, 0.23, -0.185))
	LowPoly.box(Vector3(0.12, 0.025, 0.02), Color("7a3b2e"), head, Vector3(0, 0.11, -0.185))
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	add_child(player)
	var lib := AnimationLibrary.new()
	lib.add_animation("Idle", _anim(2.0, {
		"Hips:position:y": [[0.0, 0.95], [1.0, 0.962], [2.0, 0.95]],
		"Hips/Torso/ArmL:rotation:z": [[0.0, -0.06], [1.0, -0.1], [2.0, -0.06]],
		"Hips/Torso/ArmR:rotation:z": [[0.0, 0.06], [1.0, 0.1], [2.0, 0.06]],
		"Hips/Torso/Head:rotation:x": [[0.0, 0.0], [1.0, 0.04], [2.0, 0.0]],
	}))
	lib.add_animation("Walk", _anim(1.0, _gait(0.55, 0.45, 0.03, 0.0)))
	lib.add_animation("Run", _anim(0.6, _gait(1.0, 0.9, 0.07, -0.18)))
	lib.add_animation("Jump", _anim(0.6, {
		"Hips/LegL:rotation:x": [[0.0, 0.5], [0.6, 0.5]],
		"Hips/LegR:rotation:x": [[0.0, -0.2], [0.6, -0.2]],
		"Hips/Torso/ArmL:rotation:z": [[0.0, -1.1], [0.6, -1.2]],
		"Hips/Torso/ArmR:rotation:z": [[0.0, 1.1], [0.6, 1.2]],
	}))
	lib.add_animation("Talk", _anim(1.4, {
		"Hips/Torso/Head:rotation:x": [[0.0, 0.0], [0.35, 0.12], [0.7, 0.0], [1.05, 0.12], [1.4, 0.0]],
		"Hips/Torso/ArmR:rotation:x": [[0.0, 0.0], [0.4, 0.9], [1.0, 0.7], [1.4, 0.0]],
		"Hips/Torso/ArmR:rotation:z": [[0.0, 0.0], [0.4, 0.3], [1.4, 0.0]],
	}, false))
	player.add_animation_library("", lib)


func _pivot(pivot_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = pivot_name
	n.position = pos
	parent.add_child(n)
	return n


func _gait(leg: float, arm: float, bob: float, lean: float) -> Dictionary:
	return {
		"Hips/LegL:rotation:x": [[0.0, leg], [0.5, -leg], [1.0, leg]],
		"Hips/LegR:rotation:x": [[0.0, -leg], [0.5, leg], [1.0, -leg]],
		"Hips/Torso/ArmL:rotation:x": [[0.0, -arm], [0.5, arm], [1.0, -arm]],
		"Hips/Torso/ArmR:rotation:x": [[0.0, arm], [0.5, -arm], [1.0, arm]],
		"Hips:position:y": [[0.0, 0.95], [0.25, 0.95 + bob], [0.5, 0.95], [0.75, 0.95 + bob], [1.0, 0.95]],
		"Hips/Torso:rotation:x": [[0.0, lean], [1.0, lean]],
	}


## Keys are given on a 0..1 timeline for gaits and in seconds otherwise; both are
## scaled to `length`.
func _anim(length: float, tracks: Dictionary, loop := true) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var last_key := 0.0
	for path in tracks:
		for k in tracks[path]:
			last_key = maxf(last_key, k[0])
	var time_scale := length / last_key if last_key > 0.0 else 1.0
	for path in tracks:
		var t := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(t, NodePath(path))
		a.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
		for k in tracks[path]:
			a.track_insert_key(t, k[0] * time_scale, k[1])
	return a
