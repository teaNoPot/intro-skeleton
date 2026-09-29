extends CharacterBody3D
## First-person player (press V for third person), in the spirit of Schedule I.

signal focus_changed(target: Interactable)

@export_group("Movement")
@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var crouch_speed := 1.6
@export var acceleration := 14.0
@export var air_control := 3.0
@export var jump_velocity := 4.8

@export_group("Camera")
@export var first_person := true
@export var mouse_sensitivity := 0.0022
@export var third_person_distance := 3.4
@export var eye_height := 1.62
@export var crouch_eye_height := 1.1
@export var fov := 75.0
@export var sprint_fov := 83.0
@export var head_bob := 0.035

@export_group("Interaction")
@export var reach := 3.0

@onready var rig: Node3D = $CameraRig
@onready var pitch: Node3D = $CameraRig/Pitch
@onready var arm: SpringArm3D = $CameraRig/Pitch/SpringArm3D
@onready var camera: Camera3D = $CameraRig/Pitch/SpringArm3D/Camera3D
@onready var ray: RayCast3D = $CameraRig/Pitch/SpringArm3D/Camera3D/InteractRay
@onready var model: CharacterModel = $Model

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var focused: Interactable = null
var _bob_time := 0.0
var _was_on_floor := true


func _ready() -> void:
	add_to_group("player")
	arm.add_excluded_object(get_rid())
	ray.add_exception(self)
	_apply_camera_mode()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)
	elif event.is_action_pressed("toggle_camera"):
		first_person = not first_person
		_apply_camera_mode()
	elif event.is_action_pressed("interact") and focused:
		focused.interact(self)


func look(yaw: float, pitch_delta: float) -> void:
	rig.rotate_y(yaw)
	pitch.rotation.x = clampf(pitch.rotation.x + pitch_delta, deg_to_rad(-85), deg_to_rad(80))


func _apply_camera_mode() -> void:
	arm.spring_length = 0.0 if first_person else third_person_distance
	arm.position.x = 0.0 if first_person else 0.45
	ray.target_position = Vector3(0, 0, -(reach + arm.spring_length))
	model.visible = not first_person


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	if not on_floor:
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		model.play_move("jump")

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var crouching := Input.is_action_pressed("crouch")
	var sprinting := Input.is_action_pressed("sprint") and input.y < 0.0 and not crouching
	var speed := crouch_speed if crouching else (run_speed if sprinting else walk_speed)
	var b := rig.global_transform.basis
	var dir := b.x * input.x + b.z * input.y
	dir.y = 0.0
	dir = dir.normalized() * minf(1.0, input.length())
	var k := 1.0 - exp(-(acceleration if on_floor else air_control) * delta)
	velocity.x = lerpf(velocity.x, dir.x * speed, k)
	velocity.z = lerpf(velocity.z, dir.z * speed, k)
	move_and_slide()

	var hspeed := Vector2(velocity.x, velocity.z).length()
	# the body turns toward where it's going (third person) or where you look (first person)
	var face_yaw := rig.rotation.y
	if not first_person and hspeed > 0.3:
		face_yaw = atan2(-velocity.x, -velocity.z)
	model.rotation.y = lerp_angle(model.rotation.y, face_yaw, 1.0 - exp(-12.0 * delta))
	model.update_locomotion(hspeed, is_on_floor(), velocity.y)
	if is_on_floor() and not _was_on_floor:
		model.play_action("land")
	_was_on_floor = is_on_floor()

	# camera height, head bob and sprint FOV
	var target_eye := crouch_eye_height if crouching else eye_height
	rig.position.y = lerpf(rig.position.y, target_eye, 1.0 - exp(-10.0 * delta))
	if first_person and is_on_floor() and hspeed > 0.5:
		_bob_time += delta * hspeed * 2.2
		camera.position.y = sin(_bob_time * 2.0) * head_bob
		camera.position.x = cos(_bob_time) * head_bob * 0.6
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	camera.fov = lerpf(camera.fov, sprint_fov if sprinting and hspeed > walk_speed else fov, 1.0 - exp(-6.0 * delta))

	_update_focus()


func _update_focus() -> void:
	var target: Interactable = null
	if ray.is_colliding():
		target = Interactable.find_on(ray.get_collider())
		if target and not target.enabled:
			target = null
	if target != focused:
		focused = target
		focus_changed.emit(target)
