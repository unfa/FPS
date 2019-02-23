extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func damage():
	pass

func update():
	yield(get_tree(), "idle_frame") # wait one frame, or this data will not be up to date
	print ("hud update!")
	$HP.text = "HP: " + str($"../".health)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
