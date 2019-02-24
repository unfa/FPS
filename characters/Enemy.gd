extends "res://characters/Character.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

# state machine

var state_pain = false
var state_idle = true
var state_alert = false
var state_attack = false
var state_panic = false

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

const WALK_SPEED = 300
const WALK_SPEED_SPRINT = 700

const WALK_AIR_CONTROL = 0.1

const WALK_ACCELERATION = 0.75
const WALK_DECELERATION = 0.4

const WALK_GRAVITY = 9.8 * 4
const WALK_JUMP = 5 * 2.5

func death():
	state_alive = false # kill it
	$Body.disabled = true # disable collision
	$AnimationPlayer.play("death") # play death animation

func walk(delta):
	
		# get where is the player looking currently
	var aim = $Head/Blaster.get_transform().basis
	# reset the target walking direction so we have a clean slate
	direction = Vector3()
	
	if state_alive:
		pass
		# getting user input and setting the movement direction
#		if Input.is_action_pressed("move_forward"):
#			direction -= aim.z
#		if Input.is_action_pressed("move_backward"):
#			direction += aim.z
#		if Input.is_action_pressed("move_left"):
#			direction -= aim.x
#		if Input.is_action_pressed("move_right"):
#			direction += aim.x
	#	if Input.is_action_pressed("move_crouch"):
	#		direction -= Vector3(0,1,0)
		
		# make sure we always walk along the global XZ plane, regardless of how high (or low) the player is looking
	direction.y = 0
	
	direction = direction.normalized()
	target = direction
		
	if state_alive:
		
		if $Sensors/Front.is_colliding():
			if $Sensors/Front.get_collider().name == "Player":
				emit_signal("weapon_trigger")
		
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

func enemy_hurt():
	yield(get_tree(), "idle_frame") # wait for the data to be updated
	print("Charecter hurt:", self.name, " HP: ", self.health)

func _ready():
	# start inventory for the enemy
	inventory = { "weapon_blaster": 1, "ammo_blaster": 10000 }

	connect("recieved_damage", self, "enemy_hurt")
	connect("died", self, "death")
	
	$Head/Blaster.user = self
	
	print("Enemy init passed")

func _process(delta):
	pass

func _physics_process(delta):
	walk(delta)