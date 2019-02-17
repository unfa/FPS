extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var hit = preload("res://objects/weapons/blaster/BlasterProjectileHit.tscn")

export var velocity = 35.0

#func _process(delta):
	

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _physics_process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
	if not $Collision.is_colliding():
		translate(Vector3(0, 0, -velocity * delta))
	else:
		velocity = 0
		$AudioStreamPlayer3D.stop()
		$SuperOmni.hide()
		
		#$AnimationPlayer.play("Hit")
		
		# instntiate the hit scene
		var hit_instance = hit.instance()
		# add it to the root tree
		get_tree().root.add_child(hit_instance)
		hit_instance.global_transform.origin = $Collision.get_collision_point()
		
		
		# reparent Particles to the hit scene
		var target = hit_instance
		var source = $Particles
		self.remove_child(source)
		target.add_child(source)
		source.set_owner(target)
		source.emitting = false
		#hit_instance.look_at($RayCast.get_collision_normal(), Vector3(1,0,0))
		
		# remve this projectile scene
		self.queue_free()
		

func _on_Area_area_entered(area):
	print("area entered: ", area)


func _on_Area_body_entered(body):
	print("body entered: ", body)
	
	
