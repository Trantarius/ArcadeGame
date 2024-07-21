class_name CooldownAbility
extends PlayerAbility

## Time before ability can be used again in seconds.
@export var cooldown:Stat

var _cooldown_timer:ReversibleTimer

## Sent when the relevent key is pressed
signal triggered

func _enter_tree() -> void:
	super()
	_cooldown_timer = ReversibleTimer.new()
	_cooldown_timer.name='CooldownTimer'
	add_child(_cooldown_timer)
	reset_cooldown()

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed(get_action_name()) && _cooldown_timer.is_finished()):
		triggered.emit()
		reset_cooldown()

func reset_cooldown()->void:
	_cooldown_timer.duration = cooldown.get_value()
	_cooldown_timer.reset()
	_cooldown_timer.start()

func time_left()->float:
	return _cooldown_timer.time

func portion_left()->float:
	return _cooldown_timer.time/_cooldown_timer.duration
