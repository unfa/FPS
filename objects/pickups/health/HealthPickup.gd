extends "res://objects/pickups/Pickup.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

enum HEALTH_SIZE {
	SMALL = 5,
	MEDIUM = 25,
	LARGE = 100 }
	
export(HEALTH_SIZE) var HealthSize

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#print("Health Size: ", HealthSize)
	self.contents = { "health": HealthSize }
	#print(contents)
	
	if HealthSize == SMALL:
		$MeshInstance.mesh = $"Cube.002".mesh
	elif HealthSize == MEDIUM:
		$MeshInstance.mesh = $"Cube.001".mesh
	else:
		$MeshInstance.mesh = $"Cube".mesh
	
	# force the material
	$MeshInstance.material_override = preload("res://objects/pickups/health/health_pickup_materiall.tres")
		

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Collision_body_entered(body):
	if state_active:
		if body.has_method("pickup"):
			if body.pickup(contents):
				deactivate()