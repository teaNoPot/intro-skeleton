extends CharacterBody3D
## A townsperson who wanders around the navigation mesh and stops to chat when you
## press E on them.

@export var walk_speed := 1.4
@export var wait_time := Vector2(1.0, 5.0)
@export var talk_time := 4.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: CharacterModel = $Model
@onready var talk: Interactable = $Interactable

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _wait := 0.0
var _talking := 0.0
var _listener: Node3D = null
var _stuck_time := 0.0


func _ready() -> void:
	talk.interacted.connect(_on_talked_to)
	_wait = randf_range(0.2, wait_time.y)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= gravity * delta
	var desired := Vector3.ZERO
	var face_dir := Vector3.ZERO
	if _talking > 0.0:
		_talking -= delta
		if is_instance_valid(_listener):
			face_dir = _listener.global_position - global_position
	elif agent.is_navigation_finished():
		_wait -= delta
		if _wait <= 0.0:
			_pick_destination()
	else:
		var to := agent.get_next_path_position() - global_position
		to.y = 0.0
		if to.length() > 0.05:
			desired = to.normalized() * walk_speed
			face_dir = desired
	var k := 1.0 - exp(-8.0 * delta)
	velocity.x = lerpf(velocity.x, desired.x, k)
	velocity.z = lerpf(velocity.z, desired.z, k)
	move_and_slide()

	var hspeed := Vector2(velocity.x, velocity.z).length()
	if face_dir.length() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-face_dir.x, -face_dir.z), 1.0 - exp(-6.0 * delta))
	model.update_locomotion(hspeed, is_on_floor(), velocity.y)

	# bumped into something for too long: give up and go somewhere else
	if desired.length() > 0.1 and hspeed < 0.2:
		_stuck_time += delta
		if _stuck_time > 2.0:
			_stuck_time = 0.0
			_pick_destination()
	else:
		_stuck_time = 0.0


func _pick_destination() -> void:
	var map := get_world_3d().navigation_map
	agent.target_position = NavigationServer3D.map_get_random_point(map, agent.navigation_layers, false)
	_wait = randf_range(wait_time.x, wait_time.y)


func _on_talked_to(by: Node) -> void:
	_talking = talk_time
	_listener = by as Node3D
	model.play_action("talk")
