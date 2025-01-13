extends CharacterBody3D

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.25

@export_group("Movement")
@export var speed = 3.0
@export var acceleration = 20.0
@export var fall_acceleration = 75.0
@export var jump_impulse = 20.0

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.ZERO

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Node3D = %Camera3D
@onready var pivot: = %PlayerPivot

@onready var animation_player: AnimationPlayer = $PlayerPivot/mixamo_base/AnimationPlayer

# Emitted when the player was hit by a mob.
signal got_hit

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	# Camera input handling
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	# Update camera rotation
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI/4.0, PI/3.0)
	
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_pivot.rotation.y = wrapf(_camera_pivot.rotation.y, 0, 2*PI)
	
	_camera_input_direction = Vector2.ZERO
	
	
	# Local variable to store input direction
	var raw_input = Input.get_vector("move_left","move_right","move_forward","move_backward")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction:Vector3 = forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction.normalized()
	
	
	# Update animation Player
	if move_direction != Vector3.ZERO:
		_last_movement_direction = move_direction
		if animation_player.current_animation != "PlayerAnimations/walking":
			animation_player.play("PlayerAnimations/walking")
	else:
		animation_player.play("PlayerAnimations/idle")
	
	# Update player rotation based on camera direction + movement
	var xz_camera_direction = Vector3(-sin(_camera_pivot.rotation.y),0,-cos(_camera_pivot.rotation.y))
	var player_movement_rotation
	if move_direction != Vector3.ZERO:
		player_movement_rotation = xz_camera_direction.signed_angle_to(move_direction, Vector3(0,1,0))
	else:
		player_movement_rotation = xz_camera_direction.signed_angle_to(_last_movement_direction, Vector3(0,1,0))
	pivot.rotation.y = player_movement_rotation + _camera_pivot.rotation.y
	
	# Ground Velocity
	velocity = velocity.move_toward(move_direction*speed, acceleration*delta)
	
	# Vertical Velocity
	if not is_on_floor():
		velocity.y = velocity.y - (fall_acceleration * delta)
	
	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_impulse
		
	move_and_slide()
