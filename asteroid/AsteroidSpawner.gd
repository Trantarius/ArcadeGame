extends Node

## How many asteroids will always be present
@export var asteroid_count:float = 5


## Average asteroid size
@export var mean_size:float = 512
## Standard deviation of asteroid size, multiplicative and relative to mean size
@export_range(0,1) var size_variation:float = 1

## Maximum asteroid linear momentum (larger asteroids move slower)
@export var max_linear_momentum:float = 100
## Maximum asteroid angular momentum (larger asteroids rotate slower)
@export var max_angular_momentum:float = 1


## Distance from player to spawn asteroids
@export var spawn_distance:float = 4000
## Distance from player to despawn asteroids
@export var despawn_distance:float = 5000

func _ready()->void:
	var player:Player = get_tree().get_first_node_in_group('Players')
	if(player==null):
		return
	for n in range(asteroid_count):
		spawn_asteroid(func(): return player.position + Vector2(randf_range(-despawn_distance,spawn_distance),randf_range(-despawn_distance,spawn_distance)))

func _physics_process(delta: float) -> void:
	var player:Player = get_tree().get_first_node_in_group('Players')
	if(player==null):
		return
	
	for child in get_children():
		if(player==null):
			break
		var relpos:Vector2 = child.position - player.position
		if(relpos.x < -despawn_distance):
			spawn_asteroid(func(): return player.position + Vector2(spawn_distance,(randf()-0.5)*despawn_distance))
			child.queue_free()
		elif(relpos.x > despawn_distance):
			spawn_asteroid(func(): return player.position + Vector2(-spawn_distance,(randf()-0.5)*despawn_distance))
			child.queue_free()
		elif(relpos.y < -despawn_distance):
			spawn_asteroid(func(): return player.position + Vector2((randf()-0.5)*despawn_distance,spawn_distance))
			child.queue_free()
		elif(relpos.y > despawn_distance):
			spawn_asteroid(func(): return player.position + Vector2((randf()-0.5)*despawn_distance,-spawn_distance))
			child.queue_free()

func rand_mul(std:float)->float:
	var ret:float = randfn(0,std)
	return (abs(ret)+1)**sign(ret)

func spawn_asteroid(locator:Callable)->void:
		
	var aster:Asteroid = preload("res://asteroid/asteroid.tscn").instantiate()
	add_child(aster)
	aster.radius = mean_size * rand_mul(size_variation)
	aster.noise.seed = randi()
	aster.mass = (aster.radius/50)**3
	aster.generate()
	
	var candidate:Transform2D = Transform2D(randf()*TAU,locator.call())
	while(aster.test_move(candidate,Vector2.ZERO)):
		candidate = Transform2D(randf()*TAU,locator.call())
	
	aster.transform = candidate
	aster.apply_central_impulse(Vector2.from_angle(randf()*TAU) * max_linear_momentum * rand_mul(1))
	aster.apply_torque_impulse(randfn(-1,1) * max_angular_momentum * rand_mul(1))
	
