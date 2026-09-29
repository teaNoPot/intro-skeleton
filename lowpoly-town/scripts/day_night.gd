extends Node
## Moves the sun, recolors the sky and fog, and turns street lights and windows on
## at night.

signal hour_changed(hour: float, day: int)

@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment
## Real minutes for one full in-game day.
@export var minutes_per_day := 14.0
@export_range(0.0, 24.0) var hour := 8.5
@export var day := 1
@export var paused := false

const DAY_TOP := Color("4f8fe0")
const DAY_HORIZON := Color("a9cdea")
const DUSK_HORIZON := Color("f4a261")
const DUSK_TOP := Color("5a4f8c")
const NIGHT_TOP := Color("121a3a")
const NIGHT_HORIZON := Color("2c3a63")

var _lights_on := false


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	if paused:
		return
	hour += delta * 24.0 / (minutes_per_day * 60.0)
	if hour >= 24.0:
		hour -= 24.0
		day += 1
	_apply()


func set_hour(h: float) -> void:
	hour = fposmod(h, 24.0)
	_apply()


func _apply() -> void:
	# 0 at night, 1 at noon; dusk is the bit in between
	var sun_height := sin((hour - 6.0) / 12.0 * PI)
	var daylight := clampf(sun_height * 1.6, 0.0, 1.0)
	var dusk := clampf(1.0 - absf(sun_height) * 3.0, 0.0, 1.0)
	if sun:
		var elevation := maxf(sun_height, 0.12) * 75.0
		sun.rotation_degrees = Vector3(-elevation, -90.0 + (hour - 6.0) / 12.0 * 180.0, 0.0)
		sun.light_energy = lerpf(0.3, 1.0, daylight)
		sun.light_color = Color("9fb4ff").lerp(Color("ffd6a0").lerp(Color("fff4e0"), daylight), clampf(daylight + dusk, 0.0, 1.0))
	if environment and environment.environment:
		var env := environment.environment
		var top := NIGHT_TOP.lerp(DUSK_TOP, dusk).lerp(DAY_TOP, daylight)
		var horizon := NIGHT_HORIZON.lerp(DUSK_HORIZON, dusk).lerp(DAY_HORIZON, daylight)
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial if env.sky else null
		if sky_mat:
			sky_mat.sky_top_color = top
			sky_mat.sky_horizon_color = horizon
			sky_mat.ground_horizon_color = horizon
			sky_mat.ground_bottom_color = horizon.darkened(0.6)
		env.fog_light_color = horizon
		env.ambient_light_energy = lerpf(0.55, 0.75, daylight)
	var night := 1.0 - daylight
	var on := night > 0.6
	if on != _lights_on:
		_lights_on = on
		for l in get_tree().get_nodes_in_group("streetlights"):
			l.visible = on
	get_tree().call_group("night_aware", "set_night", clampf((night - 0.4) / 0.6, 0.0, 1.0))
	hour_changed.emit(hour, day)


func clock_text() -> String:
	var h := int(hour)
	var m := int((hour - h) * 60.0)
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "Day %d · %d:%02d %s" % [day, h12, m, "AM" if h < 12 else "PM"]
