extends Interpolator

## Hides the health bar when the subject's health is full
var hide_when_full:bool = false

func _process(_delta: float) -> void:
	super(_delta)
	$ProgressBar.offset_left = -get_parent().radius*1.5
	$ProgressBar.offset_right = get_parent().radius*1.5
	$ProgressBar.offset_top = get_parent().radius*1.5
	$ProgressBar.offset_bottom = 0
	$ProgressBar.max_value = get_parent().max_health
	$ProgressBar.value = get_parent().health
	if(hide_when_full && is_equal_approx(get_parent().health,get_parent().max_health)):
		hide()
	else:
		show()
