extends Node


const BALL_RAD: float = .285
const STRENGTH_MULT: float = 800

@export var ball_scene: PackedScene
@export var rack_buffer: float = 0.008

@export var table: Node3D

var balls: Array[PoolBall]

var is_aiming: bool = false
var power: float = 0.0

var player_one: Player = Player.new()
var player_two: Player = Player.new()
var cur_player: Player = player_one

@onready var rack_rad: float = BALL_RAD + rack_buffer
@onready var row_sep: float = rack_rad * sqrt(3)

@onready var pockets: Node = %Table/Pockets

@onready var camera: Camera = %Camera
@onready var power_bar: ColorRect = $PowerBar
@onready var power_timer: Timer = $PowerTimer

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
		pocket.body_entered.connect(_on_ball_pocketed)
	rack()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_aiming:
		var time_norm = power_timer.get_time_left() / power_timer.get_wait_time()
		power = (-cos(2 * PI * time_norm) + 1) / 2
		power_bar.material.set_shader_parameter("fill",power)


func _input(event):
	if event.is_action_pressed("reset"):
		if is_aiming:
			toggle_is_aiming()
		rack()
		camera.reset_target_cam()
		camera.set_overhead()
	
	if event.is_action_pressed("hit_ball"):
		if !is_aiming and camera.aim():
			toggle_is_aiming()
		elif is_aiming and camera.shoot():
			toggle_is_aiming()
			hit_ball()
	
	if event.is_action_pressed("free_cam"):
		if !is_aiming and !camera.toggle_free_cam():
			print_debug("Camera in wrong state")
	
	if event.is_action_pressed("camera_switch"):
		if is_aiming:
			toggle_is_aiming()
			camera.set_aim_dir()
		if !is_aiming and !camera.toggle_cam():
			print_debug("Camera in wrong state")
	
	if event.is_action_pressed("cancel"):
		if is_aiming:
			toggle_is_aiming()
			camera.set_aim_dir()


# Clears all balls in the scene, then racks a new set of balls
func rack():
	for ball in balls:
		ball.queue_free()
	balls.clear()
	var ball: PoolBall = ball_scene.instantiate()
	ball.init_vals(0, head_spot)
	add_child(ball)
	balls.append(ball)
	camera.camera_target = ball
	
	var solids: Array[int] = [1,2,3,4,5,6,7]
	var stripes: Array[int] = [9,10,11,12,13,14,15]
	var corners: Array[int] = [solids.pop_at(randi_range(0,6)),stripes.pop_at(randi_range(0,6))]
	var balls_left: Array[int] = solids + stripes
	for i in rack_locs.size():
		ball = ball_scene.instantiate()
		var ball_value: int = i+1
		# ensure the eight ball is in the middle and the corners are opposite types
		if (ball_value != 8):
			if (i == 4 or i == 11):
				ball_value = corners.pop_at(randi_range(0,corners.size()-1))
			else:
				ball_value = balls_left.pop_at(randi_range(0,balls_left.size()-1))
		var spawn_loc: Vector3 = rack_locs[i]
		# add slight variation to the location of the ball
		spawn_loc.x += randf_range(-rack_buffer,rack_buffer)
		spawn_loc.z += randf_range(-rack_buffer,rack_buffer)
		ball.init_vals(ball_value, spawn_loc)
		add_child(ball)
		balls.append(ball)


func hit_ball():
	var hit_loc: Vector3 = camera.aim_decal.global_position
	var hit_dir: Vector3 = camera.target.global_position - camera.aim_cam.global_position
	var strength: float = power * STRENGTH_MULT
	camera.camera_target.strike(hit_loc,hit_dir,strength)


# Called when a ball enters a pocket
func _on_ball_pocketed(body):
	if body is PoolBall:
		if body.ball_value != 0:
			print(str(body.ball_value) + " ball pocketed")
		else:
			print("scratch")


func toggle_is_aiming():
	power_bar.visible = !power_bar.visible
	is_aiming = !is_aiming
	if power_timer.is_stopped():
		power_timer.start()
	else:
		power_timer.stop()


class Player:
	var balltype: PoolBall.BallType
	var num_pocketed: int = 0
