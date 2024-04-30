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
const TRANSITION_TIME: float = 0.2

const DISTANCE_MIN: float = 2.5
const DISTANCE_MAX: float = 20.0

var trans_start: Transform3D
var trans_end: Transform3D

@onready var target: Marker3D = $Target
@onready var spinner_y: Marker3D = $Target/SpinnerY
@onready var spinner_x: Marker3D = $Target/SpinnerY/SpinnerX
@onready var direction_decal: Decal = $Target/SpinnerY/SpinnerX/DirectionDecal
@onready var aim_decal: Decal = $Target/SpinnerY/AimDecal
@onready var overhead_cam: Camera3D = $OverheadCam
@onready var target_cam: Camera3D = $Target/SpinnerY/SpinnerX/TargetCam
@onready var aim_cam: Camera3D = $Target/SpinnerY/AimCam
@onready var free_cam: Camera3D = $FreeCam
@onready var trans_cam: Camera3D = $TransCam
@onready var stable_cam: Camera3D = $StableCam
@onready var trans_timer: Timer = $TransCam/TransTimer


# Called when the node enters the scene tree for the first time.
func _ready():
	overhead_cam.position = overhead_location.position
	
	reset_target_cam()
	
	direction_decal.visible = false
	aim_decal.visible = false
	
	cur_cam = overhead_cam
	overhead_cam.make_current()
	
	trans_timer.timeout.connect(_on_trans_timer_timeout)


# Handles input for the cameras
func _process(delta):
	# Control target camera
	target.position = camera_target.position
	if camera_state == CameraState.AIM_DIR or camera_state == CameraState.OVERHEAD:
		# Spin camera
		var rot_dir: float = Input.get_axis("camera_right","camera_left")
		spinner_y.rotate_y(rot_dir * (sqrt(max(target_cam.position.z - DISTANCE_MIN,0)) * CAMERA_SPEED * delta + .001))
		# Zoom camera
		var zoom_dir: float = Input.get_axis("camera_zoom_in","camera_zoom_out")
		target_cam.position.z += zoom_dir * ZOOM_SPEED * delta
		target_cam.position.z = clamp(target_cam.position.z, DISTANCE_MIN, DISTANCE_MAX)
		# Zoom camera with mouse wheel
		var zoom_dir_wheel: float = 0
		if Input.is_action_just_pressed("camera_zoom_in_wheel"):
			zoom_dir_wheel = -1
		if Input.is_action_just_pressed("camera_zoom_out_wheel"):
			zoom_dir_wheel = 1
		target_cam.position.z += zoom_dir_wheel * 2 * ZOOM_SPEED * delta
		target_cam.position.z = clamp(target_cam.position.z, DISTANCE_MIN, DISTANCE_MAX)
	
	# Control free camera
	if camera_state == CameraState.FREE_CAM:
		var x_dir: float = Input.get_axis("camera_left","camera_right")
		free_cam.translate_object_local(x_dir * transform.basis.x * FREE_CAM_SPEED * delta)
		var y_dir: float = Input.get_axis("camera_down","camera_up")
		free_cam.translate_object_local(y_dir * transform.basis.y * FREE_CAM_SPEED * delta)
		var z_dir: float = Input.get_axis("camera_forward","camera_backward")
		free_cam.translate_object_local(z_dir * transform.basis.z * FREE_CAM_SPEED * delta)
	
	# Move transition camera
	if camera_state == CameraState.TRANSITION:
		if !trans_timer.is_stopped():
			var t: float = (TRANSITION_TIME - trans_timer.time_left) / TRANSITION_TIME
			trans_end = next_cam.global_transform
			trans_cam.global_transform = trans_start.interpolate_with(trans_end, t)
	
	
	stable_cam.look_at(camera_target.position)


# Displays target on ball when aiming
func _physics_process(_delta):
	if camera_state == CameraState.AIM_STRIKE:
		var space_state = get_world_3d().direct_space_state
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = aim_cam.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + aim_cam.project_ray_normal(mouse_pos)
		var ray_query = PhysicsRayQueryParameters3D.create(ray_origin,ray_end,0b100)
		var raycast = space_state.intersect_ray(ray_query)
		if raycast.has("collider") and raycast["collider"] == camera_target:
			aim_decal.global_position = raycast["position"]



func _input(event):
	
	# Handles input for switching cameras
	if event.is_action_pressed("camera_switch"):
		if camera_state == CameraState.OVERHEAD:
			set_aim_dir()
		elif camera_state == CameraState.AIM_DIR:
			set_overhead()
		elif camera_state == CameraState.WATCH_SHOT:
			set_overhead()
	
	if event.is_action_pressed("hit_ball"):
		if camera_state == CameraState.AIM_DIR or camera_state == CameraState.OVERHEAD:
			set_aim_strike()
		elif camera_state == CameraState.AIM_STRIKE:
			camera_target.strike(aim_decal.global_position,aim_cam.global_position,400)
			set_watch_shot()
		elif camera_state == CameraState.WATCH_SHOT:
			set_overhead()
	
	if event.is_action_pressed("ui_cancel"):
		if camera_state == CameraState.AIM_STRIKE:
			set_aim_dir()
		elif camera_state == CameraState.WATCH_SHOT:
			set_aim_dir()
	
	if event.is_action_pressed("free_cam"):
		if camera_state == CameraState.FREE_CAM:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			set_overhead()
		elif camera_state != CameraState.TRANSITION:
			set_free_cam()
	
	# Handles mouse input for free cam
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
	next_state = CameraState.WATCH_SHOT
	next_cam = stable_cam
	stable_cam.global_position = cur_cam.global_position
	stable_cam.position.y += 3
	transition()


func set_free_cam():
	next_state = CameraState.FREE_CAM
	next_cam = free_cam
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	transition()


#transition between cameras
func transition():
	camera_state = CameraState.TRANSITION
	trans_start = cur_cam.global_transform
	trans_end = next_cam.global_transform
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
	target_cam.position.z = DISTANCE_MIN
