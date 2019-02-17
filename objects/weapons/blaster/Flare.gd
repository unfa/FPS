extends MeshInstance

export var debug = false

export(float, 0, 1) var energy = 1
export(Color, RGB) var color = Color(1,1,1,1)

export(int, 0, 100) var fade_start = 12
export(int, 0, 100) var fade_distance = 15

#export(float, 0, 1) var fade_alpha = 1
#export(float, 0, 1) var fade_scale = 1

func _ready():
	# if we start with the node visible - we'll have 1 frame delay before hiding it - this could look bad
	self.hide()	
	
	# COMPLETELY DISABLE ALL FLARES!
	set_physics_process(0)
	
	var mat = mesh.get_material().duplicate(false)
	mesh.set_material(mat)
	print(mat)

func _physics_process(delta):

	# get current camera
	var camera = get_viewport().get_camera()
	
	var pos1 = self.global_transform.origin
	var pos2 = camera.global_transform.origin
	
	# intersect a ray betwee nthe camera and the self
	var result = get_world().direct_space_state.intersect_ray(pos2, pos1, [self])
	
	# if we hit nothing - the flare is visible, so we show it
	if result.empty():
		self.show()
		var distance = pos1.distance_to(pos2) # calculate distance to camera
		
		var alpha = ( 1 - min( max(0, distance - fade_start), fade_distance) / fade_distance ) * energy
		
		var mat = mesh.get_material() # get current material
		var col = mat.get_albedo() # get teh albedo color
		
		col = Color(color.r, color.g, color.b, alpha)
		mat.set_albedo(col) # apply changes
		
		if debug:
			print (mat.get_albedo())
		
	else: # othwerwise we hide it
		self.hide()