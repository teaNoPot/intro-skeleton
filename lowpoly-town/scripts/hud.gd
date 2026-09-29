extends CanvasLayer
## Crosshair, "[E] Talk to ..." prompt, dialog box, clock and pause screen.
## Built in code so it works before you design your own UI; replace freely.

var _prompt: Label
var _crosshair: ColorRect
var _dialog: PanelContainer
var _dialog_name: Label
var _dialog_text: Label
var _clock: Label
var _hint: Label
var _pause: ColorRect
var _dialog_timer := 0.0
var _hint_timer := 14.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.85)
	_crosshair.size = Vector2(4, 4)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = Vector2(-2, -2)
	root.add_child(_crosshair)

	_prompt = _label(root, 20)
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(-200, 28)
	_prompt.size = Vector2(400, 30)

	_dialog = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.08, 0.1, 0.82)
	box.set_corner_radius_all(6)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 14
	_dialog.add_theme_stylebox_override("panel", box)
	_dialog.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialog.position = Vector2(-280, -150)
	_dialog.custom_minimum_size = Vector2(560, 0)
	_dialog.visible = false
	root.add_child(_dialog)
	var v := VBoxContainer.new()
	_dialog.add_child(v)
	_dialog_name = _label(v, 16)
	_dialog_name.add_theme_color_override("font_color", Color("ffcf87"))
	_dialog_text = _label(v, 20)
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_clock = _label(root, 20)
	_clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock.position = Vector2(-320, 16)
	_clock.size = Vector2(300, 30)

	_hint = _label(root, 15)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(20, -70)
	_hint.text = "WASD move · Shift run · Space jump · Ctrl crouch · E interact · V camera · Esc pause"

	_pause = ColorRect.new()
	_pause.color = Color(0, 0, 0, 0.55)
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.visible = false
	root.add_child(_pause)
	var pl := _label(_pause, 34)
	pl.text = "Paused\nClick or press Esc to keep playing"
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.set_anchors_preset(Control.PRESET_CENTER)
	pl.position = Vector2(-300, -50)
	pl.size = Vector2(600, 100)

	Game.paused_changed.connect(func(p: bool): _pause.visible = p)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.focus_changed.connect(_on_focus_changed)
	var day_night := get_tree().current_scene.get_node_or_null("DayNight") if get_tree().current_scene else null
	if day_night:
		day_night.hour_changed.connect(func(_h, _d): _clock.text = day_night.clock_text())


func _process(delta: float) -> void:
	if _dialog_timer > 0.0:
		_dialog_timer -= delta
		if _dialog_timer <= 0.0:
			_dialog.visible = false
	if _hint_timer > 0.0:
		_hint_timer -= delta
		_hint.modulate.a = clampf(_hint_timer, 0.0, 1.0)


func show_dialog(speaker: String, text: String) -> void:
	_dialog_name.text = speaker
	_dialog_text.text = text
	_dialog.visible = true
	_dialog_timer = 4.5


func _on_focus_changed(target: Interactable) -> void:
	_prompt.text = "[E] " + target.get_prompt() if target else ""
	_crosshair.color = Color("ffcf87") if target else Color(1, 1, 1, 0.85)


func _label(parent: Node, font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
