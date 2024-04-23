class_name PoolBall
extends RigidBody3D

enum BallType {CUE, SOLID, STRIPE}

@export_range(0,15) var ball_value: int = 0

var textures: Array[Resource] = [
	preload("res://Balls/CueBall.png"),
	preload("res://Balls/1Ball.png"),
	preload("res://Balls/2Ball.png"),
	preload("res://Balls/3Ball.png"),
	preload("res://Balls/4Ball.png"),
	preload("res://Balls/5Ball.png"),
	preload("res://Balls/6Ball.png"),
	preload("res://Balls/7Ball.png"),
	preload("res://Balls/8Ball.png"),
	preload("res://Balls/9Ball.png"),
	preload("res://Balls/10Ball.png"),
	preload("res://Balls/11Ball.png"),
	preload("res://Balls/12Ball.png"),
	preload("res://Balls/13Ball.png"),
	preload("res://Balls/14Ball.png"),
	preload("res://Balls/15Ball.png"),
]
var colliding_balls: Array[Node]
var ball_velocity: Vector3
var velocities_before_impact: Array[Vector3]
var first_hit: PoolBall = null

const SPIN_COEFFICIENT: float = 1.0

@onready var ball_type: BallType = set_type()


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the texture image based on the ball value
	var mat = $MeshInstance3D.mesh.surface_get_material(0).duplicate()
	mat.albedo_texture = textures[ball_value]
	$MeshInstance3D.set_surface_override_material(0,mat)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	ball_velocity = linear_velocity
	#if ball_type == BallType.CUE:
		#if angular_velocity.length() >= 5:
			#print(angular_velocity)


#Used with on body exited to play sound when two balls collide
func _on_body_entered(body):
	# Check to see if collision is with another ball
	if body.get_collision_layer_value(2):
		if !self in body.colliding_balls:
			colliding_balls.append(body)
			velocities_before_impact = [ball_velocity, body.ball_velocity]
		if ball_type == BallType.CUE and !first_hit:
			first_hit = body


#Used with on body entered to play sound when two balls collide
func _on_body_exited(body):
	if body.get_collision_layer_value(2):
		if body in colliding_balls:
			# Calculates the strength of the collision and plays an appropriately loud sound
			var velocities_after_impact = [ball_velocity, body.ball_velocity]
			var collision_energy: float = max((velocities_before_impact[0] - velocities_after_impact[0]).length(),
					(velocities_before_impact[1] - velocities_after_impact[1]).length())
			var volume = min(collision_energy - 32,0)
			$BallImpact.set_volume_db(volume)
			$BallImpact.play()
			colliding_balls.erase(body)


func set_type():
	# Sets ball type
	if ball_value == 0:
		return BallType.CUE
	elif ball_value <= 8:
		return BallType.SOLID
	else:
		return BallType.STRIPE


#calculates and applies all forces from a strike
func strike(hit:Vector3,origin:Vector3,strength:float):
	var pos_to_hit: Vector3 = hit - global_position
	var dir_of_force: Vector3 = global_position - origin
	var angle_from_center = (-dir_of_force).angle_to(pos_to_hit)
	var impulse:Vector3 = (dir_of_force).normalized() * strength * (cos(angle_from_center) + 1) / 2
	var torque_impulse: Vector3 = pos_to_hit.cross(SPIN_COEFFICIENT * strength * dir_of_force)
	apply_impulse(impulse)
	#apply_impulse(- strength * pos_to_hit)
	apply_torque_impulse(torque_impulse)
	print(pos_to_hit)
	print(dir_of_force)
	print(torque_impulse)
