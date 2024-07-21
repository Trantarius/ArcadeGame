extends Control

var text:String:
	set(to):
		$CenterContainer/Label.text=to
	get:
		return $CenterContainer/Label.text

var ability:CooldownAbility

func _process(_delta: float) -> void:
	if(is_instance_valid(ability)):
		$ProgressBar.max_value = 1
		$ProgressBar.value = 1-ability.portion_left()
		if($ProgressBar.value>=$ProgressBar.max_value):
			$Panel.show()
		else:
			$Panel.hide()
