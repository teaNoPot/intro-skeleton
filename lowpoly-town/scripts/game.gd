extends Node
## Global setup (autoloaded as "Game"): key bindings, mouse capture and pause.

## Default keys. Change them any time in Project > Project Settings > Input Map;
## actions that already exist there are left alone.
const ACTIONS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL, KEY_C],
	"interact": [KEY_E],
	"toggle_camera": [KEY_V],
	"pause": [KEY_ESCAPE],
}

signal paused_changed(is_paused: bool)


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _ready() -> void:
	capture_mouse(true)


func capture_mouse(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func set_paused(p: bool) -> void:
	get_tree().paused = p
	capture_mouse(not p)
	paused_changed.emit(p)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
	elif event is InputEventMouseButton and event.pressed:
		if get_tree().paused:
			set_paused(false)
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			capture_mouse(true)
