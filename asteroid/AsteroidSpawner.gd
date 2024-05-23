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
	for n:int in range(asteroid_count):
		spawn_asteroid(func()->Transform2D: return Transform2D(randf()*TAU,
			player.position + Vector2(randf_range(-despawn_distance,spawn_distance),randf_range(-despawn_distance,spawn_distance))))

func _physics_process(_delta: float) -> void:
	var centerpos:Vector2 = get_viewport().get_camera_2d().get_screen_center_position()
	
	for child:Node in get_children():
		var relpos:Vector2 = child.position - centerpos
		if(relpos.x < -despawn_distance):
			spawn_asteroid(func()->Transform2D: return Transform2D(randf()*TAU,
				centerpos + Vector2(spawn_distance,(randf()-0.5)*despawn_distance)))
			child.queue_free()
		elif(relpos.x > despawn_distance):
			spawn_asteroid(func()->Transform2D: return Transform2D(randf()*TAU,
				centerpos + Vector2(-spawn_distance,(randf()-0.5)*despawn_distance)))
			child.queue_free()
		elif(relpos.y < -despawn_distance):
			spawn_asteroid(func()->Transform2D: return Transform2D(randf()*TAU,
				centerpos + Vector2((randf()-0.5)*despawn_distance,spawn_distance)))
			child.queue_free()
		elif(relpos.y > despawn_distance):
			spawn_asteroid(func()->Transform2D: return Transform2D(randf()*TAU,
				centerpos + Vector2((randf()-0.5)*despawn_distance,-spawn_distance)))
			child.queue_free()

func spawn_asteroid(locator:Callable)->void:
		
	var aster:Asteroid = preload("res://asteroid/asteroid.tscn").instantiate()
	aster.radius = mean_size * (2**randfn(0,size_variation))
	aster.noise.seed = randi()
	aster.mass = (aster.radius/50)**3
	
	if(!Util.attempt_place_node(aster,self,locator,5)):
		aster.queue_free()
		push_error("Failed to place an asteroid after 5 attempts")
	else:
		aster.apply_central_impulse(Vector2.from_angle(randf()*TAU) * max_linear_momentum * (2**randfn(0,1)))
		aster.apply_torque_impulse(randfn(-1,1) * max_angular_momentum * (2**randfn(0,1)))
	
	
