class_name CooldownAbility
extends PlayerAbility

## Time before ability can be used again in seconds.
@export var cooldown:float
var last_used_tick:int

func _activate()->void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	var now:int = Time.get_ticks_usec()
	if(event.is_action_pressed(mod_name) && now-last_used_tick > cooldown*1_000_000):
		_activate()
		last_used_tick = now
