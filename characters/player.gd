extends "res://characters/character.gd"

var camera_angle = 0
var mouse_sensitivity = 0.2


var direction = Vector3()
var interpolation = 1
var velocity = Vector3()
var velocity_xz = Vector2()
var velocity_y = 0
var target = Vector3()
var target_xz = Vector2()
var target_y = 0

const FLY_SPEED = 300
const FLY_SPEED_SPRINT = 850

const FLY_ACCELERATION = 0.25
const FLY_DECELERATION = 0.25


const WALK_SPEED = 300
const WALK_SPEED_SPRINT = 700

const WALK_AIR_CONTROL = 0.1

const WALK_ACCELERATION = 0.75
const WALK_DECELERATION = 0.4

const WALK_GRAVITY = 9.8 * 4
const WALK_JUMP = 5 * 2.5


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
	
	# check if we should sprint or walk (sprint is default)
	if Input.is_action_pressed("move_sprint"):
		target = target * FLY_SPEED
	else:
		target = target * FLY_SPEED_SPRINT
	
	## determine if we're accelerating or decelerating
	if velocity.dot(target) > 1:
		velocity = velocity.linear_interpolate(target, FLY_ACCELERATION)
	else:
		velocity = velocity.linear_interpolate(target, FLY_DECELERATION)
	
	move_and_slide(velocity * delta)
	
	$Debug.text = "direction " + String(direction) +"\n"
	$Debug.text += "target " + String(target) +"\n"
	$Debug.text += "velocity " + String(velocity) +"\n"

func walk(delta):
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
#	if Input.is_action_pressed("move_crouch"):
#		direction -= Vector3(0,1,0)
	
	# make sure we always walk along the global XZ plane, regardless of how high (or low) the player is looking
	direction.y = 0
	
	direction = direction.normalized()
	target = direction
	
	# check if we should sprint or walk (sprint is default)
	if Input.is_action_pressed("move_sprint"):
		target = target * WALK_SPEED
	else:
		target = target * WALK_SPEED_SPRINT

	# jumping
	if Input.is_action_just_pressed("move_jump") and is_on_floor(): # if we are on the floor and want to jump
		velocity_y = WALK_JUMP # then jump
	elif is_on_floor(): # if we are on the floor, but not want to jump
		velocity_y = 0  # make sure the Y velocity is 0 so we can fall off an edge properly
	
	target_xz = Vector2(target.x, target.z) * delta
	#target_y = target.y * delta
	
	# apply gravity - only if we're in mid-air
	if not is_on_floor():
		velocity_y -= WALK_GRAVITY * delta
	
	# determine if we're accelerating or decelerating
	if velocity.dot(target) > 1:
		interpolation = WALK_ACCELERATION
	else:
		interpolation = WALK_DECELERATION
	
	# apply air_control if in mid-air
	if not is_on_floor():
		interpolation *= WALK_AIR_CONTROL
	
	# interpolate the velocity	
	velocity_xz = velocity_xz.linear_interpolate(target_xz, interpolation)
	
	# asseble the final velocity vector
	velocity = Vector3(velocity_xz.x, velocity_y, velocity_xz.y)
	
	# perform the motion
	var actual_velocity = move_and_slide(velocity, Vector3(0,1,0))
	
	$Debug.text = "direction " + String(direction) +"\n"
	$Debug.text += "target " + String(target) +"\n"
	$Debug.text += "velocity " + String(velocity) +"\n"
	$Debug.text += "actual_velocity " + String(actual_velocity) +"\n"

func _ready():
	# capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	self
	
func _input(event):
	# mouselook
	if event is InputEventMouseMotion:
		mouselook(event)
		
func _physics_process(delta):
	# walk
	walk(delta)

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
		
	
