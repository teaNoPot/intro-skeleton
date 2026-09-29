class_name CharacterModel
extends Node3D
## Wraps any character model and plays idle / walk / run / jump on it, whatever the
## file happens to call its animations.
##
## Works with packs from Kenney, Quaternius, KayKit, Synty, and with Mixamo
## animations. Give it a model in `model_scene` (or drag the model in as a child of
## this node). With no model it shows a placeholder person, so the game always runs.

## The character file (.glb, .gltf or .fbx) dragged in from the FileSystem dock.
@export var model_scene: PackedScene
## Extra animations, for example Mixamo files imported as "Animation Library".
@export var extra_libraries: Array[AnimationLibrary] = []
## Scale the model so it is this tall, in meters. 0 keeps the file's own size.
## Handy when mixing packs made at different scales.
@export var target_height := 1.75
## glTF and Mixamo characters face +Z; Godot's forward is -Z. Leave this on unless
## your character walks backwards.
@export var flip_forward := true
## Force a specific clip for a move, e.g. {"walk": "Walking_B"}. Moves without an
## entry are matched by name automatically.
@export var clip_overrides: Dictionary = {}
## Hide parts of the model by node name. Wildcards work: "*Shield*", "2H_Sword".
@export var hide_nodes: PackedStringArray = []
## Speed (m/s) at which the walk and run clips look right; playback speeds up or
## slows down around these so feet don't slide.
@export var walk_clip_speed := 1.6
@export var run_clip_speed := 4.5
## Seconds to crossfade between animations.
@export var blend_time := 0.18
## Print every clip found in the model to the Output panel.
@export var print_clips := false

## Words to look for in clip names, most specific first.
const GUESSES := {
	"idle": ["idle", "breath", "stand"],
	"walk": ["walk"],
	"run": ["run", "sprint", "jog"],
	"jump": ["jump_start", "jump_up", "jump"],
	"fall": ["fall", "jump_idle", "jump_loop", "in_air", "air"],
	"land": ["jump_land", "land"],
	"talk": ["talk", "interact", "wave", "cheer"],
	"crouch": ["crouch", "sneak"],
}
## Words that make a clip a worse match for plain locomotion.
const AVOID := ["back", "left", "right", "strafe", "pose", "turn", "1h", "2h", "melee", "ranged", "dual", "spell", "sit", "lie"]
const LOOPING := ["idle", "walk", "run", "fall", "crouch"]

var anim_player: AnimationPlayer
var clips := {}
var _current := ""
var _action_until := 0.0


func _ready() -> void:
	var model: Node3D = null
	if model_scene:
		model = model_scene.instantiate() as Node3D
		add_child(model)
	else:
		for c in get_children():
			if c is Node3D:
				model = c
				break
	if model == null:
		model = PlaceholderCharacter.new()
		add_child(model)
	elif flip_forward:
		model.rotate_y(PI)
	for pattern in hide_nodes:
		_hide_matching(model, pattern)
	if target_height > 0.0 and not (model is PlaceholderCharacter):
		var h := _model_height(model)
		if h > 0.01:
			model.scale *= target_height / h
	anim_player = _find_anim_player(model)
	if anim_player == null:
		push_warning("%s: no AnimationPlayer in the model, it will not animate." % get_path())
		return
	for lib in extra_libraries:
		if lib == null:
			continue
		var lib_name := lib.resource_path.get_file().get_basename() if lib.resource_path != "" else "extra%d" % anim_player.get_animation_library_list().size()
		if not anim_player.has_animation_library(lib_name):
			anim_player.add_animation_library(lib_name, lib)
	_resolve_clips()
	if print_clips:
		print("%s clips: %s" % [name, ", ".join(anim_player.get_animation_list())])
		print("%s picked: %s" % [name, clips])
	play_move("idle")


## Call every physics frame with how fast the character moves.
func update_locomotion(horizontal_speed: float, on_floor: bool, vertical_speed: float) -> void:
	if anim_player == null or Time.get_ticks_msec() / 1000.0 < _action_until:
		return
	if not on_floor:
		if vertical_speed > 0.5 and has_move("jump"):
			play_move("jump")
		elif has_move("fall"):
			play_move("fall")
		return
	if horizontal_speed < 0.15:
		play_move("idle")
	elif not has_move("run") or horizontal_speed < (walk_clip_speed + run_clip_speed) * 0.5:
		play_move("walk", clampf(horizontal_speed / walk_clip_speed, 0.6, 1.8))
	else:
		play_move("run", clampf(horizontal_speed / run_clip_speed, 0.7, 1.5))


## Play a looping move ("idle", "walk", "run", ...). Falls back to idle if missing.
func play_move(move: String, speed_scale := 1.0) -> void:
	if anim_player == null:
		return
	var clip: String = clips.get(move, clips.get("idle", ""))
	if clip == "":
		return
	if clip != _current:
		anim_player.play(clip, blend_time)
		_current = clip
	anim_player.speed_scale = speed_scale


## Play a one-shot move ("talk", "land", ...) once, then go back to walking around.
## Returns false if the model has no matching clip.
func play_action(move: String) -> bool:
	if anim_player == null or not clips.has(move):
		return false
	var clip: String = clips[move]
	anim_player.speed_scale = 1.0
	anim_player.play(clip, blend_time)
	_current = clip
	_action_until = Time.get_ticks_msec() / 1000.0 + anim_player.get_animation(clip).length
	return true


func has_move(move: String) -> bool:
	return clips.has(move)


func _resolve_clips() -> void:
	clips.clear()
	var names := anim_player.get_animation_list()
	for move in GUESSES:
		var forced: String = clip_overrides.get(move, "")
		if forced != "":
			if anim_player.has_animation(forced):
				clips[move] = forced
			else:
				push_warning("%s: clip_overrides[%s] = \"%s\" is not in the model." % [name, move, forced])
			continue
		var best := ""
		var best_score := -INF
		for guess in GUESSES[move]:
			for full in names:
				var short: String = full.get_file().to_lower()  # drops the "library/" part
				if full.to_lower().contains("mixamo"):
					short = full.get_base_dir().to_lower()  # Mixamo clips are named after their file
				if not short.contains(guess):
					continue
				var score := 100.0 if short == guess else (50.0 if short.begins_with(guess) else 10.0)
				for word in AVOID:
					if short.contains(word) and not guess.contains(word):
						score -= 30.0
				score -= short.length() * 0.5
				if score > best_score:
					best_score = score
					best = full
			if best != "":
				break
		if best != "":
			clips[move] = best
	for move in LOOPING:
		if clips.has(move):
			anim_player.get_animation(clips[move]).loop_mode = Animation.LOOP_LINEAR


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_anim_player(c)
		if found:
			return found
	return null


func _hide_matching(n: Node, pattern: String) -> void:
	for c in n.get_children():
		if c is Node3D and String(c.name).matchn(pattern):
			c.visible = false
		_hide_matching(c, pattern)


func _model_height(model: Node3D) -> float:
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	# measure the body only: hats, weapons and shields hang off bones and move around
	var skinned := meshes.filter(func(m): return (m as MeshInstance3D).skin != null)
	if skinned.size() > 0:
		meshes = skinned
	var box := AABB()
	var first := true
	for mi in meshes:
		var m := mi as MeshInstance3D
		if m.mesh == null or not _visible_within(m, model):
			continue
		var xf := model.global_transform.affine_inverse() * m.global_transform
		var b := xf * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.size.y


## Visible relative to the model itself (ignores whether the whole character is hidden,
## like the player's own body in first person).
func _visible_within(n: Node, top: Node) -> bool:
	while n != null and n != top:
		if n is Node3D and not (n as Node3D).visible:
			return false
		n = n.get_parent()
	return true
