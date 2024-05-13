class_name CooldownAbility
extends PlayerAbility

## Time before ability can be used again in seconds.
@export var cooldown:float
var cooldown_timer:CountdownTimer = CountdownTimer.new()

## Sent when the relevent key is pressed
signal triggered

func _unhandled_input(event: InputEvent) -> void:
	if(!is_active):
		return
	if(event.is_action_pressed(mod_name) && cooldown_timer.time<=0):
		triggered.emit()
		cooldown_timer.time = cooldown
