class_name AutoFireAbility
extends PlayerAbility

## Number of times [signal fire] is emitted per second.
var fire_rate:Stat = Stat.new(3, 0.01666, 60)

@export var base_fire_rate:float:
	get:
		return fire_rate.base
	set(to):
		fire_rate.base=to

signal fired

func _enter_tree()->void:
	super()
	while(is_inside_tree()):
		await get_tree().create_timer(1.0/fire_rate.get_value(),false).timeout
		fired.emit()
