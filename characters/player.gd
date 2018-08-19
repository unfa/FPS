extends "res://characters/character.gd"

var camera_angle = 0
var mouse_sensitivity = 0.2

func _ready():
	# capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	# mouselook
	if event is InputEventMouseMotion:
		# apply Y rotation (turn the head)
		$Head.rotate_y(-deg2rad(event.relative.x) * mouse_sensitivity)
		
		# calculate the X rotation (angle the camera)
		var camera_angle_change = -event.relative.y * mouse_sensitivity
		var camera_angle_new = camera_angle + camera_angle_change
		
		# clip the camera angle
		#TODO - this gives some room for error, so it could be improved later, but it's quite good for now
		if camera_angle_new < 90 and camera_angle_new > -90:
			$Head/Camera.rotate_x(deg2rad(camera_angle_change))
			camera_angle += camera_angle_change
	

func _process(delta):
	
	$Debug.text = "Gravity: " + String(Input.get_gravity())
	$Debug.text += "\nGyroscope: " + String(Input.get_gyroscope())
	$Debug.text += "\nAccelerometer: " + String(Input.get_accelerometer())
	$Debug.text += "\nMagnetometer: " + String(Input.get_magnetometer())
	
	# exit game
	if Input.is_action_just_pressed("game_exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	