extends Node3D

const BALL_RAD: float = .285

@export var target: RigidBody3D
@export var force_origin: Node3D
@export var hit_force: float = 10.0

@export var ball_scene: PackedScene
@export var rack_buffer: float = 0.005

var balls: Array[PoolBall]

@onready var rack_rad: float = BALL_RAD + rack_buffer
@onready var row_sep: float = rack_rad * sqrt(3)

@onready var head_spot: Vector3 = $Table/HeadSpot.position
@onready var foot_spot: Vector3 = $Table/FootSpot.position
@onready var rack_locs: Array[Vector3] = [
	foot_spot,
	foot_spot + Vector3(-row_sep, 0, -rack_rad),
	foot_spot + Vector3(-2.0 * row_sep, 0, -2.0 * rack_rad),
	foot_spot + Vector3(-3.0 * row_sep, 0, -3.0 * rack_rad),
	foot_spot + Vector3(-4.0 * row_sep, 0, -4.0 * rack_rad),
	foot_spot + Vector3(-4.0 * row_sep, 0, -2.0 * rack_rad),
	foot_spot + Vector3(-3.0 * row_sep, 0, -1.0 * rack_rad),
	foot_spot + Vector3(-2.0 * row_sep, 0, 0.0 * rack_rad),
	foot_spot + Vector3(-3.0 * row_sep, 0, 1.0 * rack_rad),
	foot_spot + Vector3(-4.0 * row_sep, 0, 0.0 * rack_rad),
	foot_spot + Vector3(-4.0 * row_sep, 0, 2.0 * rack_rad),
	foot_spot + Vector3(-4.0 * row_sep, 0, 4.0 * rack_rad),
	foot_spot + Vector3(-3.0 * row_sep, 0, 3.0 * rack_rad),
	foot_spot + Vector3(-2.0 * row_sep, 0, 2.0 * rack_rad),
	foot_spot + Vector3(-row_sep, 0, rack_rad),
]

# Called when the node enters the scene tree for the first time.
func _ready():
	rack()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("reset"):
		for ball in balls:
			ball.queue_free()
		rack()
	#if Input.is_action_just_pressed("hit_ball"):
		#var targetDir: Vector3 = target.position - force_origin.position
		#targetDir.y = 0
		#target.apply_impulse(hit_force * targetDir.normalized())

# Clears all balls in the scene, then racks a new set of balls
func rack():
	balls.clear()
	var ball = ball_scene.instantiate()
	ball.set_collision_layer_value(3,true)
	ball.ball_value = 0
	ball.position = head_spot
	ball.rotate_y(-PI/2)
	add_child(ball)
	balls.append(ball)
	target = ball
	$Camera.camera_target = ball
	$Camera.reset_target_cam()
	for i in rack_locs.size():
		ball = ball_scene.instantiate()
		ball.ball_value = i + 1
		ball.position = rack_locs[i]
		if i != 0:
			ball.position.x += randf_range(-rack_buffer,rack_buffer)
			ball.position.z += randf_range(-rack_buffer,rack_buffer)
		ball.rotate_y(-PI/2)
		add_child(ball)
		balls.append(ball)
