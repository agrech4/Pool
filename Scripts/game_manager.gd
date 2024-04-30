extends Node

const BALL_RAD: float = .285

@export var ball_scene: PackedScene
@export var rack_buffer: float = 0.005

@export var table: Node3D

var balls: Array[PoolBall]

@onready var rack_rad: float = BALL_RAD + rack_buffer
@onready var row_sep: float = rack_rad * sqrt(3)

@onready var camera: Camera = %Camera

@onready var pockets: Node = %Table/Pockets

@onready var head_spot: Vector3 = %Table/HeadSpot.position
@onready var foot_spot: Vector3 = %Table/FootSpot.position
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
	for pocket in pockets.get_children():
		pocket.body_entered.connect(_on_body_entered)
	rack()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _input(event):
	if event.is_action_pressed("reset"):
		rack()
		camera.reset_target_cam()
		camera.set_overhead()


# Clears all balls in the scene, then racks a new set of balls
func rack():
	for ball in balls:
		ball.queue_free()
	balls.clear()
	var ball = ball_scene.instantiate()
	ball.set_collision_layer_value(3,true)
	ball.ball_value = 0
	ball.position = head_spot
	ball.rotate_y(-PI/2)
	add_child(ball)
	balls.append(ball)
	camera.camera_target = ball
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


func _on_body_entered(body):
	if body is PoolBall:
		if body.ball_value != 0:
			print(str(body.ball_value) + " ball pocketed")
		else:
			print("scratch")
