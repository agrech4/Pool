class_name Camera
extends Node3D

enum CameraState {OVERHEAD, AIM_DIR, AIM_STRIKE, WATCH_SHOT, FREE_CAM, TRANSITION}

@export var overhead_location: Marker3D
@export var camera_target: Node3D

var camera_state: CameraState = CameraState.OVERHEAD

var vertical_angle: float = 1.0

var free_cam_rot_x: float = 0
var free_cam_rot_y: float = 0

var cur_cam: Camera3D
var next_cam: Camera3D
var next_state: CameraState

const CAMERA_SPEED: float = 1.0
const FREE_CAM_SPEED: float = 5.0
const ZOOM_SPEED: float = 50.0
const LOOKAROUND_SPEED: float = .005
const TRANSITION_TIME: float = 0.001

const DISTANCE_MIN: float = 2.5
const DISTANCE_MAX: float = 20.0

@onready var target: Marker3D = get_node("Target")
@onready var spinner_y: Marker3D = get_node("Target/SpinnerY")
@onready var spinner_x: Marker3D = get_node("Target/SpinnerY/SpinnerX")
@onready var direction_decal: Decal = get_node("Target/SpinnerY/SpinnerX/DirectionDecal")
@onready var aim_decal: Decal = get_node("Target/SpinnerY/AimDecal")
@onready var overhead_cam: Camera3D = get_node("OverheadCam")
@onready var target_cam: Camera3D = get_node("Target/SpinnerY/SpinnerX/TargetCam")
@onready var aim_cam: Camera3D = get_node("Target/SpinnerY/AimCam")
@onready var free_cam: Camera3D = get_node("FreeCam")
@onready var trans_cam: Camera3D = get_node("TransCam")
@onready var trans_timer: Timer = get_node("TransCam/TransTimer")


# Called when the node enters the scene tree for the first time.
func _ready():
	overhead_cam.position = overhead_location.position
	
	reset_target_cam()
	
	direction_decal.visible = false
	aim_decal.visible = false
	
	cur_cam = overhead_cam
	overhead_cam.make_current()
	
	trans_timer.timeout.connect(_on_trans_timer_timeout)


# Called every frame. 'delta' is the elapsed time since the previous frame.
# Handles input in regards to the cameras
func _process(delta):
	target.position = camera_target.position
	if camera_state == CameraState.AIM_DIR or camera_state == CameraState.OVERHEAD:
		if Input.is_action_pressed("camera_left"):
			spinner_y.rotate_y(sqrt(max(target_cam.position.z - DISTANCE_MIN,0)) * CAMERA_SPEED * delta + .001)
		if Input.is_action_pressed("camera_right"):
			spinner_y.rotate_y(-sqrt(max(target_cam.position.z - DISTANCE_MIN,0)) * CAMERA_SPEED * delta - .001)
		if Input.is_action_pressed("camera_zoom_in"):
			if target_cam.position.z > DISTANCE_MIN:
				target_cam.position.z -= ZOOM_SPEED * delta
		if Input.is_action_pressed("camera_zoom_out"):
			if target_cam.position.z < DISTANCE_MAX:
				target_cam.position.z += ZOOM_SPEED * delta
		if Input.is_action_just_pressed("camera_zoom_in_wheel"):
			if target_cam.position.z > DISTANCE_MIN:
				target_cam.position.z -= 2 * ZOOM_SPEED * delta
		if Input.is_action_just_pressed("camera_zoom_out_wheel"):
			if target_cam.position.z < DISTANCE_MAX:
				target_cam.position.z += 2 * ZOOM_SPEED * delta
	
	if camera_state == CameraState.FREE_CAM:
		if Input.is_action_pressed("camera_left"):
			free_cam.translate_object_local(-transform.basis.x * FREE_CAM_SPEED * delta)
		if Input.is_action_pressed("camera_right"):
			free_cam.translate_object_local(transform.basis.x * FREE_CAM_SPEED * delta)
		if Input.is_action_pressed("camera_down"):
			free_cam.translate_object_local(-transform.basis.y * FREE_CAM_SPEED * delta)
		if Input.is_action_pressed("camera_up"):
			free_cam.translate_object_local(transform.basis.y * FREE_CAM_SPEED * delta)
		if Input.is_action_pressed("camera_forward"):
			free_cam.translate_object_local(-transform.basis.z * FREE_CAM_SPEED * delta)
		if Input.is_action_pressed("camera_backward"):
			free_cam.translate_object_local(transform.basis.z * FREE_CAM_SPEED * delta)
	
	if camera_state == CameraState.TRANSITION:
		if !trans_timer.is_stopped():
			var t: float = (TRANSITION_TIME - trans_timer.time_left) / TRANSITION_TIME
			var start: Transform3D = cur_cam.global_transform
			var end: Transform3D = next_cam.global_transform
			trans_cam.global_transform = start.interpolate_with(end, t)


# Displays target on ball when aiming
func _physics_process(_delta):
	if camera_state == CameraState.AIM_STRIKE:
		var space_state = get_world_3d().direct_space_state
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = aim_cam.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + aim_cam.project_ray_normal(mouse_pos) * 50
		var ray_query = PhysicsRayQueryParameters3D.create(ray_origin,ray_end,2)
		var raycast = space_state.intersect_ray(ray_query)
		if raycast.has("collider") and raycast["collider"] == camera_target:
			aim_decal.global_position = raycast["position"]


# Handles input for switching cameras
func _input(event):
	if event.is_action_pressed("camera_switch"):
		if camera_state == CameraState.OVERHEAD:
			set_aim_dir()
		elif camera_state == CameraState.AIM_DIR:
			set_overhead()
	
	if event.is_action_pressed("hit_ball"):
		if camera_state == CameraState.AIM_DIR or camera_state == CameraState.OVERHEAD:
			set_aim_strike()
		elif camera_state == CameraState.AIM_STRIKE:
			camera_target.strike(aim_decal.global_position,aim_cam.global_position,200)
			set_watch_shot()
	
	if event.is_action_pressed("ui_cancel"):
		if camera_state == CameraState.AIM_STRIKE:
			set_aim_dir()
	
	if event.is_action_pressed("free_cam"):
		if camera_state == CameraState.FREE_CAM:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			set_overhead()
		elif camera_state != CameraState.TRANSITION:
			set_free_cam()
	
	if camera_state == CameraState.FREE_CAM:
		if event is InputEventMouseMotion:
			free_cam_rot_x -= event.relative.x * LOOKAROUND_SPEED
			free_cam_rot_y -= event.relative.y * LOOKAROUND_SPEED
			free_cam.transform.basis = Basis()
			free_cam.rotate_object_local(Vector3(0,1,0),free_cam_rot_x)
			free_cam.rotate_object_local(Vector3(1,0,0),free_cam_rot_y)

func set_overhead():
	next_state = CameraState.OVERHEAD
	next_cam = overhead_cam
	aim_decal.visible = false
	transition()


func set_aim_dir():
	next_state = CameraState.AIM_DIR
	next_cam = target_cam
	direction_decal.visible = true
	aim_decal.visible = false
	transition()


func set_aim_strike():
	next_state = CameraState.AIM_STRIKE
	next_cam = aim_cam
	direction_decal.visible = false
	aim_decal.visible = true
	transition()


func set_watch_shot():
	set_aim_dir()
	#set_overhead()
	#camera_state = CameraState.OVERHEAD
	#target.position = overhead_location.position
	#spinner.rotation.x = - PI / 2
	#spinner.rotation.y = 0
	#camera.position.z = 2.5
	#direction_decal.visible = false
	#aim_decal.visible = false


func set_free_cam():
	next_state = CameraState.FREE_CAM
	next_cam = free_cam
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	transition()


#transition between cameras
func transition():
	camera_state = CameraState.TRANSITION
	trans_timer.set_wait_time(TRANSITION_TIME)
	trans_timer.start()
	trans_cam.make_current()


func _on_trans_timer_timeout():
	camera_state = next_state
	cur_cam = next_cam
	next_cam.make_current()


func reset_target_cam():
	target.position = camera_target.position
	spinner_y.rotation.y = PI / 2
	spinner_x.rotation.x = - PI / 6
	target_cam.position.z = DISTANCE_MIN
