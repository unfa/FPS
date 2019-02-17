extends OmniLight

export(float, 0, 1) var threshold_on = 0.5
export(float, 0, 1) var threshold_off = 0.2
export(float, 0, 1) var smooth_on = 0.3
export(float, 0, 1) var smooth_off = 0.8
export(int, 1, 1000) var delay_base = 15
export(int, 1, 1000) var delay_random = 15

var delay = delay_base

var desired_energy = self.light_energy
var step = 0
var choice = 0
var choice_prev = choice
var power = true
var power_prev = power

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func flicker(delta):	
	step += 1
	if step >= delay:
		step = 0
		delay = delay_base + rand_range(0, delay_random)
		
	choice_prev = choice
	if step == 0:
		choice = rand_range(0,1)
		
	#print(choice)
	
	power_prev = power
	if choice >= threshold_on:
		power = true
	elif choice <= threshold_off:
		power = false
		
	if power:
		self.light_energy = lerp(self.light_energy, desired_energy, 1 - smooth_on)
		if not power_prev:
			$On.play()
			#$Flare.show()
	else:
		self.light_energy = lerp(self.light_energy, 0, 1 - smooth_off)
		if power_prev:
			$Off.play()
			#$Flare.hide()
		
		
		
#	if choice >= threshold_on:
#		self.light_energy = lerp(self.light_energy, desired_energy, 1 - smooth_up)
#	elif choice <= threshold_off:
#		self.light_energy = lerp(self.light_energy, 0, 1 - smooth_down)
		
	
	# sound playback
	
#	if previous_choice <= threshold_off and choice >= threshold_on: # light just went on
#		$On.play()
#	elif previous_choice >= threshold_on and choice <= threshold_off: # light just went off
#		$Off.play()
		
	#print ("delay: ", delay, "\tchoice: ", choice, "\tt_on: ", threshold_on, "\tt_off: ", threshold_off)

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	flicker(delta)
	
	$Flare.energy = light_energy
	$Flare.color = light_color

