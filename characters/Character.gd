extends KinematicBody

# all characters have health
export var health = 100
export var health_max = 100

# state machine
var state_alive = true

func heal(hp): #  increase health
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
	health -= hp
	if health <= 0: # if we're dead now
		die() # initiate death sequence

func kill():
	if state_alive:
		
		if health > 0:
			health = 0
			
		state_alive = false
		return true # announce success
	else:
		return false # you can't kill something that's dead!

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
