extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass
	
func _input(event):
	if Input.is_action_just_pressed("weapon_fire_primary"): # check if the primary fire action was just pressed
		if $"../../../..".inventory.has("ammo_blaster"): # check if we have the proper ammo in inventory
			if $"../../../..".inventory["ammo_blaster"] > 0: #check if the amount is higher than zero
				$AnimationPlayer.play("FirePrimary") # run the animation
				$"../../../..".inventory["ammo_blaster"] -= 1 # consume ammo

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
