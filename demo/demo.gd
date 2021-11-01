extends Control


func _ready():
	$Settings/NStrikes/NStrikesSlider.value = $Lightning.NUM_STRIKES
	$Settings/TimeBetweenStrikes/TimeSlider.value = $Lightning.TIME_BETWEEN_STRIKES


func _physics_process(_delta):
	$FPSCounter.text = "FPS: " + str(Engine.get_frames_per_second())


func _on_GenerateButton_pressed():
	$Lightning.generate()


func _on_NStrikesSlider_value_changed(value):
	$Settings/NStrikes/Number.text = "(" + str(int(value)) + ")"
	$Lightning.NUM_STRIKES = int(value)


func _on_TimeBetweenStrikesSlider_value_changed(value):
	$Settings/TimeBetweenStrikes/Number.text = "(" + str(value) + ")"
	$Lightning.TIME_BETWEEN_STRIKES = value


func _on_BranchChanceSlider_value_changed(value):
	$Settings/BranchChance/Number.text = "(" + str(value) + ")"
	$Lightning.BRANCH_CHANCE = value
