class_name CooldownAbility
extends PlayerAbility

## Time before ability can be used again in seconds.
@export var cooldown:float
var cooldown_timer:CountdownTimer = CountdownTimer.new()

func _trigger()->void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if(!is_active):
		return
	if(event.is_action_pressed(mod_name) && cooldown_timer.time<=0):
		_trigger()
		cooldown_timer.time = cooldown
