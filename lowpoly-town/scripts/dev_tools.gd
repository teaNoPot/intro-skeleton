class_name DevTools
extends Node
## Command-line helpers for testing without opening the editor:
##   godot --path . -- --smoke-test            run checks and quit (exit code 1 on failure)
##   godot --path . -- --screenshot=shot.png   save a screenshot and quit
##   extra options: --hour=19.5  --third-person  --turn=90  --look-down=10
##                  --model=res://path.glb  --hide=*Sword*,*Shield*

var args := {}
var failures := 0


static func attach_if_requested(main: Node) -> void:
	var a := {}
	for arg in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.trim_prefix("--").split("=", true, 1)
		a[parts[0]] = parts[1] if parts.size() > 1 else "1"
	if a.has("smoke-test") or a.has("screenshot"):
		var t := DevTools.new()
		t.args = a
		main.add_child(t)


func _ready() -> void:
	var main := get_parent()
	var player = main.get_node("Player")
	if args.has("hour"):
		main.get_node("DayNight").set_hour(float(args["hour"]))
		main.get_node("DayNight").paused = true
	if args.has("third-person"):
		player.first_person = false
		player._apply_camera_mode()
	if args.has("model"):
		_swap_player_model(player, load(args["model"]))
	if args.has("turn"):
		player.look(deg_to_rad(float(args["turn"])), 0.0)
	if args.has("look-down"):
		player.look(0.0, -deg_to_rad(float(args["look-down"])))
	if args.has("smoke-test"):
		await _smoke_test(main, player)
		print("SMOKE TEST: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
		get_tree().quit(1 if failures else 0)
	elif args.has("screenshot"):
		await _frames(int(args.get("frames", "90")))
		var img := get_viewport().get_texture().get_image()
		img.save_png(args["screenshot"])
		print("saved ", args["screenshot"])
		get_tree().quit()


func _swap_player_model(player: Node, scene: PackedScene) -> void:
	var old: CharacterModel = player.get_node("Model")
	var m := CharacterModel.new()
	m.name = "Model"
	m.model_scene = scene
	m.print_clips = true
	if args.has("hide"):
		m.hide_nodes = PackedStringArray(String(args["hide"]).split(","))
	old.name = "OldModel"
	old.queue_free()
	player.add_child(m)
	player.model = m
	player._apply_camera_mode()


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _smoke_test(main: Node, player: Node) -> void:
	await _frames(20)
	var map: RID = main.get_world_3d().navigation_map
	var npcs: Array = main.get_node("NPCs").get_children()
	_check(npcs.size() > 0, "spawned %d townspeople" % npcs.size())
	_check(NavigationServer3D.map_get_random_point(map, 1, false) != Vector3.ZERO, "navigation mesh baked")
	_check(player.is_on_floor(), "player is standing on the ground at %s" % player.global_position)
	var pm: CharacterModel = player.get_node("Model")
	_check(pm.has_move("idle") and pm.has_move("walk") and pm.has_move("run"), "player model has idle/walk/run: %s" % pm.clips)

	var start: Vector3 = player.global_position
	Input.action_press("move_forward")
	await _frames(60)
	_check(player.global_position.distance_to(start) > 1.5, "walks forward (%.1f m in 1 s)" % player.global_position.distance_to(start))
	_check(pm._current.to_lower().contains("walk"), "walk animation playing (%s)" % pm._current)
	Input.action_press("sprint")
	await _frames(40)
	var v: Vector3 = player.velocity
	_check(Vector2(v.x, v.z).length() > 4.5, "sprints (%.1f m/s)" % Vector2(v.x, v.z).length())
	Input.action_release("sprint")
	Input.action_release("move_forward")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(8)
	_check(not player.is_on_floor(), "jumps")
	await _frames(60)
	_check(player.is_on_floor(), "lands again")

	var positions := npcs.map(func(n): return n.global_position)
	await _frames(180)
	var moved := 0
	for i in npcs.size():
		if npcs[i].global_position.distance_to(positions[i]) > 0.5:
			moved += 1
	_check(moved >= npcs.size() / 3, "townspeople wander (%d of %d moved)" % [moved, npcs.size()])

	# put someone in front of the player and look at them
	var npc: Node3D = npcs[0]
	var cam: Camera3D = player.camera
	var fwd := -cam.global_transform.basis.z
	fwd.y = 0.0
	npc.global_position = player.global_position + fwd.normalized() * 1.8
	npc.set_physics_process(false)
	player.pitch.rotation.x = deg_to_rad(-12)
	await _frames(6)
	_check(player.focused != null, "looking at a townsperson shows a prompt (%s)" % (player.focused.get_prompt() if player.focused else "none"))
	if player.focused:
		player.focused.interact(player)
		var hud = main.get_node("HUD")
		_check(hud._dialog.visible, "talking opens the dialog: \"%s\"" % hud._dialog_text.text)
	npc.set_physics_process(true)

	var dn = main.get_node("DayNight")
	dn.set_hour(22.0)
	var lights := get_tree().get_nodes_in_group("streetlights")
	_check(lights.size() > 0 and lights[0].visible, "street lights on at night (%d lights)" % lights.size())
	dn.set_hour(12.0)
	_check(lights.size() > 0 and not lights[0].visible, "street lights off at noon")

	if args.has("model"):
		var m: CharacterModel = player.get_node("Model")
		_check(m.anim_player != null, "custom model has an AnimationPlayer")
		_check(m.has_move("idle") and m.has_move("walk") and m.has_move("run"), "custom model clips: %s" % m.clips)
		var h: float = m._model_height(m.get_child(0)) * m.get_child(0).scale.y
		_check(absf(h - m.target_height) < 0.1, "custom model scaled to %.2f m" % h)
