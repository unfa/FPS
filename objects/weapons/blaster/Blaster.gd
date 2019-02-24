extends Spatial

signal weapon_empty

var fire_ready = true

var user = null

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
const projectile = preload("res://objects/weapons/blaster/BlasterProjectile.tscn")

func set_ready(state):
	fire_ready = state
	#print(fire_ready)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# get the player node
	connect("weapon_empty", user, "weapon_empty")
	pass
	
func trigger():
	if fire_ready:
		if user.inventory.has("ammo_blaster") and user.inventory["ammo_blaster"] > 0: # check if we have the proper ammo in inventory and check if the amount is higher than zero
				$AnimationPlayer.play("FirePrimary") # run the animation
				user.inventory["ammo_blaster"] -= 1 # consume ammo
				
				#instantiate the projectile
				var projectile_instance = projectile.instance()
				projectile_instance.global_transform = $ProjectileSpawner.global_transform
				projectile_instance.user = user
				get_tree().root.add_child(projectile_instance)
		else:
			emit_signal("weapon_empty")
	
#func _input(event):
#	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	#print(fire_ready)
	pass