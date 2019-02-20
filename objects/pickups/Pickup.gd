extends Spatial

const rotation_rate = 1

var contents = {
	#"weapon_blaster": 1,
	#"ammo_blaster": 25,
	#"health": 10
	}

# state machine

var state_active = true

func activate():
	state_active = true
	$MeshInstance.show()

func deactivate():
	state_active = false
	hide()
	
func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#print(name + ": " + String(contents))
	pass

func _process(delta):
	$MeshInstance.rotate_y(rotation_rate * delta)

func _on_Area_body_entered(body):
	if state_active:
		if body.has_method("pickup"):
			if body.pickup(contents):
				deactivate()
