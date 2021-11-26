extends Control


func _ready():
	$CanvasLayer2/Settings/NStrikes/NStrikesSlider.value = $Lightning.NUM_OF_STRIKES
	$CanvasLayer2/Settings/TimeBetweenStrikes/TimeSlider.value = $Lightning.TIME_BETWEEN_STRIKES


func _physics_process(_delta):
	$CanvasLayer2/FPSCounter.text = "FPS: " + str(Engine.get_frames_per_second())


func _on_GenerateButton_pressed():
	$Lightning.simulate()


func _on_NStrikesSlider_value_changed(value):
	$CanvasLayer2/Settings/NStrikes/Number.text = "(" + str(int(value)) + ")"
	$Lightning.NUM_OF_STRIKES = int(value)


func _on_TimeBetweenStrikesSlider_value_changed(value):
	$CanvasLayer2/Settings/TimeBetweenStrikes/Number.text = "(" + str(value) + ")"
	$Lightning.TIME_BETWEEN_STRIKES = value


func _on_BranchChanceSlider_value_changed(value):
	$CanvasLayer2/Settings/BranchChance/Number.text = "(" + str(value) + ")"
	$Lightning.MAX_BRANCH_CHANCE = value
