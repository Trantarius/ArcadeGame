class_name SpikyFactory
extends Enemy

## Seconds between Spiky spawning events
@export var spawn_time:float = 3

## Time until next spawn event
var spawn_timer:float = 0

func _ready() -> void:
	$'.'.apply_force(-self.linear_velocity)
	$'.'.apply_torque(-self.angular_velocity+1)

func _physics_process(delta: float) -> void:
	
	spawn_timer-=delta
	if(spawn_timer<=0):
		spawn_timer = spawn_time
		spawn_spiky()

func spawn_spiky()->void:
	var dir:Vector2 = global_transform.basis_xform(Vector2.RIGHT).rotated(randf()*TAU)
	var spiky:Spiky = preload("res://enemies/spiky/spiky.tscn").instantiate()
	spiky.position = position + dir * 32
	spiky.linear_velocity = dir * 200
	spiky.add_collision_exception_with(self)
	get_parent().add_child(spiky)
