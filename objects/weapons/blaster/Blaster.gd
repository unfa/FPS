extends Spatial

signal weapon_empty

var delay = 0.5 # firing delay
var user = null # who's weilding the weapon? (Will be filled by the user himself)
var ready = true # is the gun ready to fire the next shot (by default it is)

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

# preload the projectile scene
const projectile = preload("res://objects/weapons/blaster/BlasterProjectile.tscn")

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	# connect event to user so he can reac to firing an empty gun
	connect("weapon_empty", user, "weapon_empty")
	pass
	
func trigger():
	if not ready: # if the gun is not ready - ignore the request
		return 1
	
	#  if the user has any ammo for the weapon, we can fire	it
	if user.inventory.has("ammo_blaster") and user.inventory["ammo_blaster"] > 0: 
		ready = false # make sure the user can't fire more than one shot at a time
		user.inventory["ammo_blaster"] -= 1 # consume ammo
		$AnimationPlayer.play("FirePrimary") # run the animation 
			
		#instantiate the projectile
		var projectile_instance = projectile.instance()
		projectile_instance.global_transform = $ProjectileSpawner.global_transform
		projectile_instance.user = user
		get_tree().root.add_child(projectile_instance)
		
		# create fire delay
		yield(get_tree().create_timer(delay), "timeout")
		
		# unlock the gun for the next shot
		ready = true
	else: # if we have no ammo - let the user know
		emit_signal("weapon_empty")
	

#func _process(delta):
#	pass