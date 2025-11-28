extends CharacterBody3D

@export_group("headbob")
@export var headbob_frequency = 2.0
@export var headbob_amplitude = 0.06
var headbob_time = 0.0

@onready var timer = $Timer
var sprinting = false
var default_speed = 5.5
var sprint_speed = 9.0
var speed = default_speed

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.3
		%Head.rotation_degrees.x -= event.relative.y * 0.2
		%Head.rotation_degrees.x = clamp(%Head.rotation_degrees.x, -80.0, 80.0)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _physics_process(delta):
	speed = default_speed

	var input_direction_2D = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var input_direction_3D = Vector3(input_direction_2D.x, 0.0, input_direction_2D.y)
	var direction = transform.basis * input_direction_3D

	if Input.is_action_just_pressed("sprint") and not sprinting:
		sprinting = true
		timer.start()
	elif Input.is_action_just_released("sprint"):
		sprinting = false
		timer.stop()

	if sprinting:
		speed = sprint_speed
	else:
		speed = default_speed

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	velocity.y -= 20.0 * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 10.0
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5

	move_and_slide()

	headbob_time += delta * velocity.length() * float(is_on_floor())
	%Camera3D.transform.origin = headbob(headbob_time)

func headbob(time):
	var headbob_position = Vector3.ZERO
	headbob_position.y = sin(time * headbob_frequency) * headbob_amplitude
	headbob_position.x = cos(time * headbob_frequency / 2) * headbob_amplitude
	return headbob_position

func _on_timer_timeout() -> void:
	sprinting = false
