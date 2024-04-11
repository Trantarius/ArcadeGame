class_name SpikyFactory
extends Actor

## Seconds between Spiky spawning events
@export var spawn_time:float = 10
## Constant rotation speed
@export var spin_speed:float = 0.5

## Time until next spawn event
@onready var spawn_timer:float = spawn_time

func _physics_process(delta: float) -> void:
	rotate(spin_speed * delta)
	
	super(delta)
	
	spawn_timer-=delta
	if(spawn_timer<=0):
		spawn_timer = spawn_time
		spawn_spikies()

func spawn_spikies()->void:
	for n in range(6):
		var dir:Vector2 = global_transform.basis_xform(Vector2.RIGHT).rotated(n*TAU/6)
		var spiky:Spiky = preload("res://spiky/spiky.tscn").instantiate()
		spiky.position = position + dir * 32
		spiky.velocity = dir * spiky.max_speed
		spiky.add_collision_exception_with(self)
		get_parent().add_child(spiky)
