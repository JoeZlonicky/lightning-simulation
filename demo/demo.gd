extends Control


func _ready():
	$UILayer/Settings/TimeBetweenStrikes/TimeSlider.value = $Lightning.TIME_BETWEEN_STRIKES
	$UILayer/Settings/BranchChance/BranchChanceSlider.value = $Lightning.MAX_BRANCH_CHANCE


func _physics_process(_delta):
	$UILayer/FPSCounter.text = "FPS: " + str(Engine.get_frames_per_second())


func _on_SimulateButton_pressed():
	$UILayer/SimulateButton.disabled = true
	$Lightning.simulate()


func _on_TimeBetweenStrikesSlider_value_changed(value):
	$UILayer/Settings/TimeBetweenStrikes/Number.text = "(" + str(value) + ")"
	$Lightning.TIME_BETWEEN_STRIKES = value


func _on_BranchChanceSlider_value_changed(value):
	$UILayer/Settings/BranchChance/Number.text = "(" + str(value) + ")"
	$Lightning.MAX_BRANCH_CHANCE = value


func _on_SingleStrikeButton_pressed():
	$Lightning.single_strike()


func _on_StartStopButton_pressed():
	if $UILayer/SimulationButtons/StartStopButton.pressed:
		$UILayer/SimulationButtons/SingleStrikeButton.disabled = true
		$Lightning.start_simulation()
	else:
		$UILayer/SimulationButtons/SingleStrikeButton.disabled = false
		$Lightning.end_simulation()
	


func _on_Lightning_strike_completed():
	$UILayer/PathNotFound.visible = false


func _on_Lightning_path_not_found():
	$UILayer/PathNotFound.visible = true
