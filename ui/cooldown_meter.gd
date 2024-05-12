extends Control

var text:String:
	set(to):
		$Label.text=to
	get:
		return $Label.text

var timer:CooldownTimer=CooldownTimer.new()

func reset(time:float)->void:
	timer.time=time
	$ProgressBar.max_value=time
	$ProgressBar.value=time
	$Panel.hide()

func _process(_delta: float) -> void:
	$ProgressBar.value = timer.time
	if($ProgressBar.value<=0):
		$Panel.show()
