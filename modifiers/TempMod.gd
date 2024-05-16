class_name TempMod
extends Modifier

## How long the mod lasts.
@export var lifetime:float = 10
var lifetime_timer:Timer
var timed_out:bool = false

func _init()->void:
	activated.connect(_tmp_activate)
	deactivated.connect(_tmp_deactivate)

func _tmp_activate()->void:
	lifetime_timer = Timer.new()
	add_child(lifetime_timer)
	lifetime_timer.timeout.connect(func():
		timed_out=true
		get_parent().remove_modifier(mod_name)
		queue_free())

func _tmp_deactivate()->void:
	if(!timed_out):
		lifetime_timer.stop()
		lifetime_timer.queue_free()
