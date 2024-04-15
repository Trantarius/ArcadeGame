class_name SpikyFactory
extends Enemy

## Seconds between Spiky spawning events
@export var spawn_time:float = 10

## Time until next spawn event
var spawn_timer:float = 0

func _ready() -> void:
	linear_target = Vector2.ZERO
	angular_target = max_angular_speed

func _physics_process(delta: float) -> void:
	
	spawn_timer-=delta
	if(spawn_timer<=0):
		spawn_timer = spawn_time
		spawn_spikies()

func spawn_spikies()->void:
	for n:int in range(6):
		var dir:Vector2 = global_transform.basis_xform(Vector2.RIGHT).rotated(n*TAU/6)
		var spiky:Spiky = preload("res://spiky/spiky.tscn").instantiate()
		spiky.position = position + dir * 32
		spiky.linear_velocity = dir * spiky.max_linear_speed/2
		spiky.add_collision_exception_with(self)
		get_parent().add_child(spiky)
