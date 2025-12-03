extends CharacterBody3D

@export var transition_path: NodePath
var transition_player = null

@export var headbob_frequency = 2.0
@export var headbob_amplitude = 0.06
var headbob_time = 0.0

@export var healthbar_path: NodePath
@export var healthlabel_path: NodePath
var healthbar = null
var healthlabel = null
var health = 100

@onready var timer = $Timer
var sprinting = false
var default_speed = 5.5
var sprint_speed = 9.0
var speed = default_speed

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	healthbar = get_node(healthbar_path)
	healthlabel = get_node(healthlabel_path)
	set_health()

	transition_player = get_node(transition_path)

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

func set_health() -> void:
	healthbar.value = health
	healthlabel.text = "HP: %d" % health + "%"

func damage(amount: int) -> void:
	health -= amount
	set_health()

func _on_timer_timeout() -> void:
	sprinting = false

func _on_killzone_body_entered(body:Node3D) -> void:
	if body == self:
		call_deferred("reload_scene")

func reload_scene() -> void:
	transition_player.play("fade_out")
	await transition_player.animation_finished
	get_tree().reload_current_scene()
