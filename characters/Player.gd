extends "res://characters/Character.gd"

enum PLATFORM{desktop, mobile} # are we running on desktop or mobile?

var platform = 0

var camera_angle = 0 # camera tilt (up/down)
var mouse_sensitivity = 0.2 # multiplier for mouse motion input
var gyro_sensitivity = 0.2 # multipier for gyroscope input
var gyro_lerp = 0.5 # motion smoothing for the gyroscope (helps with shaky hands)
var gyro = Vector3() # current gyroscope input
var gyro_previous = Vector3() # previous frame's gyroscope input

var direction = Vector3() # motion vector (relative to Player's rotation)
var interpolation = 1  # 
var velocity = Vector3() # target motion velocity 
var actual_velocity = Vector3() # current motion velocity (we're constanlty lerping it to the velocity)
var velocity_xz = Vector2() # the horizonal plane component of the velocity
var velocity_y = 0 # the vertical axis component of the movement vector
var target = Vector3() 
var target_xz = Vector2()
var target_y = 0

### the follwing is to implement fall damage
# TODO - implement fall damage
var velocity_previous = Vector3()
var on_floor_previous = true
const UNSAFE_VELOCITY = 1000 # how fast we need to hit something to get damage (not tested)
const UNSAFE_VELOCITY_FACTOR = 0.1 # how much damage for every length unit of the velocit vector on hit (not tested)

# movement mode constants
const FLY_SPEED = 300 # how fast can you fly?
const FLY_SPEED_SPRINT = 850 # how fast can you fly in a hurry?

const FLY_ACCELERATION = 0.25 # lerp factor for increasing velocity
const FLY_DECELERATION = 0.25 # lerp factor for decreasing velocity

const WALK_SPEED = 300 # walking on the ground
const WALK_SPEED_SPRINT = 700 # running on the ground

const WALK_AIR_CONTROL = 0.1 # how much effect do you hae on your XZ motion when not touching the ground?

const WALK_ACCELERATION = 0.75 # lerping for gaing speed
const WALK_DECELERATION = 0.4 # lerping for loosing speed

const WALK_GRAVITY = 9.8 * 4 # how much the gravity pulls you down?
const WALK_JUMP = 5 * 2.5 # the jump force/speed/height

### HOW PLAYER MOVEMENT WORKS
# The Player's root node (Kinematic Body) moves, but never rotates. What rotates is the head (left/right). and camera (up/down)
# This might be changed later if it proves a better solution - the movement could use some clean up (especialy teh vars/consts and their names)
# I think the movement is pretty pleasant and it feels very good to me (- unfa)

func damage():
	$AnimationPlayer.play("damage")
	if health >= 70:
		$"Head/Sounds/Damage 1".play()
	elif health >= 50:
		$"Head/Sounds/Damage 2".play()
	elif health > 0:
		$"Head/Sounds/Damage 3".play()
	else:
		$"Head/Sounds/Death".play()

func weapon_empty():
	$Head/Sounds/Empty.play() # play a sound effect to let the user know he's running dry

func debug(): # this function show some debug data on screen - it's easier to look at than a bunch of prints
	# each frame start wiht a clean slate
	$"HUD/Debug".text = ""

	# then add some text
	$"HUD/Debug".text += "Player camera euler: " + String($"Head/Camera".global_transform.basis.get_euler()) +"\n"
	
	#$"HUD/Debug".text += "Player.basis.z " + String($"Head".global_transform.basis.z) +"\n"
	
	# get the global vector we're loooking at
	
#	$DebugL.text += "direction " + String(direction) +"\n"
#	$DebugL.text += "target " + String(target) +"\n"
#	$DebugL.text += "velocity " + String(velocity) +"\n"
#	$DebugL.text += "actual_velocity " + String(actual_velocity) +"\n"
#
#	$DebugL.text += "health " + String(health) +"\n"
#	$DebugL.text += "inventory " + String(inventory) +"\n"
#
#	$DebugR.text = String(Engine.get_frames_per_second()) + " FPS"
#
#	$DebugL.text += "on_floor_previous " + String(on_floor_previous) + "\n"
#
#	$DebugL.text += "feet_collision_count " + String(feet_collision_count) + "\n"
#	$DebugL.text += "feet_collision " + String(check_feet_collision()) + "\n"
#
#	$DebugL.text += "platform " + String(PLATFORM.keys()[platform]) + "\n"
#	$DebugL.text += "gyro " + String(gyro) + "\n"
	
	# print out sensor information
#	$Debug.text = "Gravity: " + String(Input.get_gravity())
#	$Debug.text += "\nGyroscope: " + String(Input.get_gyroscope())
#	$Debug.text += "\nAccelerometer: " + String(Input.get_accelerometer())
#	$Debug.text += "\nMagnetometer: " + String(Input.get_magnetometer())

func pickup(contents): # function that takes stuff from the world and puts them in your inventory
	var consumed = false # track if we actually use anything , by default we don't - for example we won't use a health pickup if we're at 100 health, so there's not reason to waste it
	for item in contents: # for every item in the pickup contents do
		if item == "health": # if we're picking up health packs
			if heal(contents[item]): # let's use them immediately - there's no health items we can use later (this is not an RPG game!)
				consumed = true # mark the pickup as used, so the item itself will be consumed
		else:
			if inventory.has(item): # check if we already have this type of item
				inventory[item] += contents[item] # increase the stock amount
				consumed = true
			else: # if we don't have any yet
				inventory[item] = contents[item] # create a new entry in the inventory 
				consumed = true
	
	return consumed # tell the pickup object if it should disappear, or not

func mouselook(event): # this function takes mouse movement input and applies it to player and camera rotation
	
	# apply Y rotation (turn the head left and right)
	$Head.rotate_y(-deg2rad(event.relative.x) * mouse_sensitivity)
	
	# calculate the X rotation (angle the camera up and down)
	var camera_angle_change = -event.relative.y * mouse_sensitivity
	var camera_angle_new = camera_angle + camera_angle_change
	
	# clip the camera angle - the player can't turn his head up forever
	#TODO - this gives some room for error, so it could be improved later, but it's quite good for now
	if camera_angle_new < 90 and camera_angle_new > -90:
		$Head/Camera.rotate_x(deg2rad(camera_angle_change))
		camera_angle += camera_angle_change

func gyrolook(): # this function takes gyroscope input (mobile devices) and applies it to player and camera rotation
	gyro_previous = gyro  # store last frames' data so we can apply time interpolation (smooth out the input)
	
	# get this frame's gyroscope data, and lerp it with the previous frme's data so we get time smoothing
	gyro = Input.get_gyroscope().linear_interpolate(gyro_previous, gyro_lerp)

	# apply Y rotation (turn the head left and right)
	$Head.rotate_y(gyro.y * gyro_sensitivity)
	
	# calculate the X rotation (angle the camera up and down)
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
	inventory = { "weapon_blaster": 1, "ammo_blaster": 100 }
	
	# determine of we're running on desktop or mobile platforms:
	if OS.get_name() in ["Android", "iOS"]:
		platform = PLATFORM.mobile
	else:
		platform = PLATFORM.desktop
	
	# capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connect Trigger input to weapon Nodes
	self.connect("weapon_trigger", $Head/Camera/WeaponHandle/Blaster, "trigger")
	self.connect("recieved_damage", self, "damage")
	
	#connect("died", self, "death")
	
	$Head/Camera/WeaponHandle/Blaster.user = self
	
	
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
	debug()
		
	# exit game
	if Input.is_action_just_pressed("game_exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	
