extends Control

var text:String:
	set(to):
		$Label.text=to
	get:
		return $Label.text

var ability:CooldownAbility

func _process(_delta: float) -> void:
	$ProgressBar.max_value = ability.cooldown
	$ProgressBar.value = ability.cooldown - ability.cooldown_timer.time
	if($ProgressBar.value>=$ProgressBar.max_value):
		$Panel.show()
	else:
		$Panel.hide()
