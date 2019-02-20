extends "res://characters/Character.gd"

enum PLATFORM{desktop, mobile}

var platform = 0

var camera_angle = 0
var mouse_sensitivity = 0.2
var gyro_sensitivity = 0.2
var gyro_lerp = 0.5
var gyro = Vector3()
var gyro_previous = Vector3()

var inventory = {} # storting all the stuff players can pick up

var direction = Vector3()
var interpolation = 1
var velocity = Vector3()
var actual_velocity = Vector3()
var velocity_xz = Vector2()
var velocity_y = 0
var target = Vector3()
var target_xz = Vector2()
var target_y = 0

### the follwing is to implement fall damage
var velocity_previous = Vector3()
var on_floor_previous = true
const UNSAFE_VELOCITY = 1000 # how fast we need to hit something to get damage
const UNSAFE_VELOCITY_FACTOR = 0.1 # how much damage for every length unit of the velocit vector on hit


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

func weapon_empty():
	$Head/Empty.play()

func debug():
	$DebugL.text = ""

	$DebugL.text += "direction " + String(direction) +"\n"
	$DebugL.text += "target " + String(target) +"\n"
	$DebugL.text += "velocity " + String(velocity) +"\n"
	$DebugL.text += "actual_velocity " + String(actual_velocity) +"\n"
	
	$DebugL.text += "health " + String(health) +"\n"
	$DebugL.text += "inventory " + String(inventory) +"\n"
	
	$DebugR.text = String(Engine.get_frames_per_second()) + " FPS"
	
	$DebugL.text += "on_floor_previous " + String(on_floor_previous) + "\n"
	
	$DebugL.text += "feet_collision_count " + String(feet_collision_count) + "\n"
	$DebugL.text += "feet_collision " + String(check_feet_collision()) + "\n"
	
	$DebugL.text += "platform " + String(PLATFORM.keys()[platform]) + "\n"
	$DebugL.text += "gyro " + String(gyro) + "\n"
	
	# print out sensor information
#	$Debug.text = "Gravity: " + String(Input.get_gravity())
#	$Debug.text += "\nGyroscope: " + String(Input.get_gyroscope())
#	$Debug.text += "\nAccelerometer: " + String(Input.get_accelerometer())
#	$Debug.text += "\nMagnetometer: " + String(Input.get_magnetometer())

func pickup(contents):
	var used = false # track if we actually use anything
	for item in contents: # for ecvery item in the pickup do
		if item == "health": # if we're picking up health packs
			if heal(contents[item]): # let's use the immediately
				used = true
		else:
			if inventory.has(item): # check if we already have this type of item
				inventory[item] += contents[item] # increase the stock amount
				used = true
			else: # if we don't have any yet
				inventory[item] = contents[item] # create a new entry in the inventory 
				used = true
	
	return used # tell the pickup object if we got it, so it can deactivate

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

func gyrolook():
	gyro_previous = gyro
	gyro = Input.get_gyroscope().linear_interpolate(gyro_previous, gyro_lerp)

	# apply Y rotation (turn the head)
	$Head.rotate_y(gyro.y * gyro_sensitivity)
	
	# calculate the X rotation (angle the camera)
	var camera_angle_change = rad2deg(gyro.x) * mouse_sensitivity
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
	
	if is_on_floor() and not on_floor_previous: # if we've just hit the ground
		pass
	
func walk(delta):
		# get where is the player looking currently
	var aim = $Head/Camera.get_camera_transform().basis
	# reset the target direction so we havea clean slate
	direction = Vector3()
	
	if state_alive:
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
		
	if state_alive:
		# check if we should sprint or walk (sprint is default)
		if Input.is_action_pressed("move_sprint"):
			target = target * WALK_SPEED
		else:
			target = target * WALK_SPEED_SPRINT
	
		# jumping
		if Input.is_action_just_pressed("move_jump") and is_on_floor(): # if we are on the floor and want to jump
			velocity_y = WALK_JUMP # then jump
		elif is_on_floor(): # if we are on the floor, but not want to jump
			velocity_y = -0.15  # make sure the Y velocity is low, so we can fall off an edge properly
		
		target_xz = Vector2(target.x, target.z) * delta
		#target_y = target.y * delta
	else:
		target = Vector3()
		target_xz = Vector2()
		
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
	
	# store data for future reference
	velocity_previous = velocity
	on_floor_previous = is_on_floor()
	
	# perform the motion
	actual_velocity = move_and_slide(velocity, Vector3(0,1,0))
	
func _ready():
	
	# basic inventory
	inventory = { "blaster": 1, "ammo_blaster": 100 }
	
	# determine of we're running on desktop or mobile platforms:
	if OS.get_name() in ["Android", "iOS"]:
		platform = PLATFORM.mobile
	else:
		platform = PLATFORM.desktop
	
	# capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connect Trigger input to weapon Nodes
	self.connect("weapon_trigger", $Head/Camera/WeaponHandle/Blaster, "trigger")
	
	# Connect Player Events to HUD Scene
	self.connect("recieved_damage", $HUD, "update")
	self.connect("recieved_health", $HUD, "update")
	self.connect("died", $HUD, "update")
	
	

	
func _input(event):
	# mouselook
	if state_alive:
		if event is InputEventMouseMotion:
			mouselook(event)
		
		if event is InputEventMouseButton:
			if Input.is_action_pressed("weapon_fire_primary"):
				emit_signal("weapon_trigger")
		
func _physics_process(delta):
	
	if platform == PLATFORM.mobile:
		gyrolook()
	
	# walk
	walk(delta)

func _process(delta):
	#debug()
		
	# exit game
	if Input.is_action_just_pressed("game_exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	
