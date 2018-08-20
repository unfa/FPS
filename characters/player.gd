extends "res://characters/character.gd"

var camera_angle = 0
var mouse_sensitivity = 0.2

var direction = Vector3()
var velocity = Vector3()
var target = Vector3()

const FLY_SPEED = 150
const FLY_SPEED_SPRINT = 300

const WALK_SPEED = 150
const WALK_SPEED_SPRINT = 300

const WALK_ACCELERATION = 1
const WALK_DECELERATION = 10

const FLY_ACCELERATION = 1
const FLY_DECELERATION = 10

func mouselook(event):
	# apply Y rotation (turn the head)
		$Head.rotate_y(-deg2rad(event.relative.x) * mouse_sensitivity)
		
		# calculate the X rotation (angle the camera)
		var camera_angle_change = -event.relative.y * mouse_sensitivity
		var camera_angle_new = camera_angle + camera_angle_change
		
		# clip the camera angle
		#TODO - this gives some room for error, so it could be improved later, but it's quite good for now
		if camera_angle_new < 90 and camera_angle_new > -90:
			$Head/Camera.rotate_x(deg2rad(camera_angle_change))
			camera_angle += camera_angle_change
			
func fly(delta):
		# get where is the player looking currently
	var aim = $Head/Camera.get_camera_transform().basis
	
	# reset the target direction so we havea clean slate
	direction = Vector3()
		
	# getting user input and setting the movement direction
	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
	if Input.is_action_pressed("move_backward"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x
	if Input.is_action_pressed("move_crouch"):
		direction -= Vector3(0,1,0)
	if Input.is_action_pressed("move_jump"):
		direction += Vector3(0,1,0)
	
	direction = direction.normalized()
	
	target = direction
	
	# check if we should sprint
	if Input.is_action_pressed("move_sprint"):
		target = target * FLY_SPEED_SPRINT
	else:
		target = target * FLY_SPEED
	
	if velocity.dot(target) > 1:
		velocity = velocity.linear_interpolate(target, FLY_ACCELERATION * delta)
	else:
		velocity = velocity.linear_interpolate(target, FLY_DECELERATION * delta)
	
	move_and_slide(velocity)
	
	$Debug.text = "direction " + String(direction) +"\n"
	$Debug.text += "target " + String(target) +"\n"
	$Debug.text += "velocity " + String(velocity) +"\n"

func _ready():
	# capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	
	# mouselook
	if event is InputEventMouseMotion:
		mouselook(event)
		
func _physics_process(delta):
	
	fly(delta)	

func _process(delta):
	# print out sensor information
#	$Debug.text = "Gravity: " + String(Input.get_gravity())
#	$Debug.text += "\nGyroscope: " + String(Input.get_gyroscope())
#	$Debug.text += "\nAccelerometer: " + String(Input.get_accelerometer())
#	$Debug.text += "\nMagnetometer: " + String(Input.get_magnetometer())
	
	# exit game
	if Input.is_action_just_pressed("game_exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
		
	