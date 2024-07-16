class_name CooldownAbility
extends PlayerAbility

## Time before ability can be used again in seconds.
var cooldown:Stat = Stat.new(5, 0.1, INF)

@export var base_cooldown:float:
	get:
		return cooldown.base
	set(to):
		cooldown.base=to

var _timer:SceneTreeTimer
var last_cooldown:float = -1
var cooldown_ready:bool = false

## Sent when the relevent key is pressed
signal triggered

func _enter_tree() -> void:
	super()
	reset_cooldown()

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed(get_action_name()) && cooldown_ready):
		triggered.emit()
		reset_cooldown()

func reset_cooldown()->void:
	cooldown_ready = false
	last_cooldown = cooldown.get_value()
	_timer = get_tree().create_timer(last_cooldown,false)
	_timer.timeout.connect(func()->void:
		cooldown_ready=true)

func time_left()->float:
	if(cooldown_ready):
		return 0
	if(is_instance_valid(_timer)):
		return _timer.time_left
	return cooldown.get_value()

func portion_left()->float:
	if(cooldown_ready):
		return 0
	if(is_instance_valid(_timer)):
		return _timer.time_left/last_cooldown
	return 1
