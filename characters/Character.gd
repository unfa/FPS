extends KinematicBody

signal recieved_damage
signal recieved_health
signal recieved_item
signal died
signal weapon_trigger
signal weapon_change

# all characters have health
export var health = 100
export var health_max = 100

var inventory = {} # storting all the stuff players can pick up

var feet_collision_count = 0
var feet_collision = false

# state machine
var state_alive = true

func check_feet_collision():
	if feet_collision_count > 0:
		return true
	else:
		return false
		
func death():
	state_alive = false # kill it
	$Body.disabled = true # disable body collision
	$Ground.disabled = false # enable ground collision
	$AnimationPlayer.play("death") # play death animation
	self.collision_layer

func heal(hp): #  increase health

	emit_signal("recieved_health")
	# store the current health
	var health_old = health

	# increate health by the given amount
	if health < health_max: # only if we're not on maximum health already
		health += hp
	else: # otherwise return false
		return false

	# check if we exceeded the maximum health after healing
	if health > health_max:
		health = health_max

	return health_old - health # return the actual amount healed

func hurt(hp): # do damage
	emit_signal("recieved_damage")

	health -= hp
	if health <= 0: # if we're dead now
		kill() # initiate death sequence

func kill():
	
	if state_alive:
		emit_signal("died")
		
		if health > 0:
			health = 0
			
		state_alive = false
		return true # announce success
	else:
		return false # you can't kill something that's dead!

func _ready():
	connect("died", self, "death")

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Feet_body_entered(body):
	print(body)
	feet_collision_count += 1
	print("feet collision: " + String(feet_collision_count))


func _on_Feet_body_exited(body):
	print(body)
	feet_collision_count -= 1
	print("feet collision: " + String(feet_collision_count))
