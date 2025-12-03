extends CharacterBody3D

var player = null
enum State { IDLE, PATROLLING, CHASING }
var state_machine = State.PATROLLING

@export var patrol_speed = 200.0
@export var chase_speed = 400.0
@export var player_path: NodePath
@export var patrol_path: NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var FOV_caster = $RayCast3D

var all_points = []
var next_point = 0
var seen_player = false

func _ready() -> void:
	player = get_node(player_path)
	for x in get_node(patrol_path).get_children():
		all_points.append(x.global_position + Vector3(0, 1, 0))

func _physics_process(delta: float) -> void:
	var overlapping = $hitbox.get_overlapping_bodies()
	for body in overlapping:
		if body.is_in_group("player"):
			body.damage(1)
	
	match state_machine:
		State.IDLE:
			velocity = Vector3.ZERO
		State.PATROLLING:
			patrolling(delta)
		State.CHASING:
			velocity = Vector3.ZERO

			nav_agent.target_position = player.global_position
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_position).normalized() * chase_speed * delta

			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	move_and_slide()

func patrolling(delta):
	var dir_dir

	nav_agent.target_position = all_points[next_point]
	dir_dir = (nav_agent.get_next_path_position() - global_position).normalized()

	velocity = velocity.lerp(dir_dir * 120.0 * delta, 0.1)

	dir_dir.y = 0
	var old = transform.basis
	look_at(global_position + dir_dir + Vector3(0.1, 0, 0), Vector3.UP)
	var new = transform.basis
	transform.basis = lerp(old.orthonormalized(), new.orthonormalized(), .1)

func check_sight():
	if seen_player:
		FOV_caster.look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3(0, 1, 0))

	if FOV_caster.is_colliding():
		var collider = FOV_caster.get_collider()

		if collider.is_in_group("player"):
			state_machine = State.CHASING

	if player.global_position.distance_to(global_position) > 16.0:
		state_machine = State.PATROLLING
	elif player.global_position.distance_to(global_position) < 5.0 and not is_target_in_bounds(player.global_position):
		state_machine = State.PATROLLING

func _on_fov_body_entered(body:Node3D) -> void:
	if body.is_in_group("player"):
		seen_player = true
		state_machine = State.CHASING
		check_sight()

func _on_fov_body_exited(body:Node3D) -> void:
	if body.is_in_group("player"):
		seen_player = false

func _on_timer_timeout() -> void:
	check_sight()
	nav_agent.set_target_position(player.global_position)

func _on_navigation_agent_3d_target_reached() -> void:
	next_point += 1
	if next_point >= all_points.size():
		next_point = 0

func is_target_in_bounds(target_pos: Vector3) -> bool:
	var map_rid = nav_agent.get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(map_rid, target_pos)
	return closest_point.distance_to(target_pos) < 2.0
