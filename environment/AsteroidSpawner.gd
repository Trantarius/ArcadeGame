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
## Makes asteroids move towards the screen center (<0 to disable)
@export var motion_target_radius:float = -1

func _ready()->void:
	await get_tree().physics_frame
	for n:int in range(asteroid_count):
		await spawn_asteroid_anywhere()

func _physics_process(_delta: float) -> void:
	var centerpos:Vector2 = Util.current_camera_pos()
	
	for child:Asteroid in get_children():
		if((child.position-centerpos).length()-child.radius>despawn_distance):
			spawn_asteroid_dir(centerpos-child.position)
			child.queue_free()

func spawn_asteroid_dir(dir:Vector2)->void:
	var aster:Asteroid = preload("res://environment/asteroid.tscn").instantiate()
	var svar:float = randfn(0,size_variation)
	svar = sign(svar) * fposmod(abs(svar),2*size_variation)
	aster.radius = mean_size * 2**svar
	aster.noise.seed = randi()
	aster.mass = (aster.radius/50)**2
	await aster.generate()
	
	var tform:Transform2D = Transform2D(randf()*TAU, Util.current_camera_pos() + 
		Vector2.from_angle(dir.angle()+randfn(0,0.5)) * (spawn_distance + aster.radius + randf()*(despawn_distance-spawn_distance)))
	while(!Util.does_node_fit(aster, tform)):
		await get_tree().physics_frame
		svar = randfn(0,size_variation)
		svar = sign(svar) * fposmod(abs(svar),2*size_variation)
		aster.radius = mean_size * 2**svar
		aster.noise.seed = randi()
		aster.mass = (aster.radius/50)**2
		await aster.generate()
		tform = Transform2D(randf()*TAU, Util.current_camera_pos() + 
			Vector2.from_angle(dir.angle()+randfn(0,0.5)) * (spawn_distance + aster.radius + randf()*(despawn_distance-spawn_distance)))
	
	aster.transform = tform
	add_child.call_deferred(aster)
	await aster.tree_entered
	
	if(motion_target_radius<0):
		aster.apply_central_impulse(Vector2.from_angle(randf()*TAU) * max_linear_momentum * (2**randfn(0,1)))
	else:
		var target:Vector2 = Vector2.from_angle(randf()*TAU)*sqrt(randf())*motion_target_radius + Util.current_camera_pos()
		var momentum:Vector2 = (target - aster.position).normalized() * max_linear_momentum * (2**randfn(0,1))
		aster.apply_central_impulse(momentum)
		
	aster.apply_torque_impulse(randfn(-1,1) * max_angular_momentum * (2**randfn(0,1)))

func spawn_asteroid_anywhere()->void:
	var aster:Asteroid = preload("res://environment/asteroid.tscn").instantiate()
	var svar:float = randfn(0,size_variation)
	svar = sign(svar) * fposmod(abs(svar),2*size_variation)
	aster.radius = mean_size * 2**svar
	aster.noise.seed = randi()
	aster.mass = (aster.radius/50)**2
	await aster.generate()
	
	var tform:Transform2D = Transform2D(randf()*TAU, Util.current_camera_pos() + 
		Vector2.from_angle(randf()*TAU) * sqrt(randf()) * ((spawn_distance+despawn_distance)/2 + aster.radius))
	while(!Util.does_node_fit(aster, tform)):
		await get_tree().physics_frame
		svar = randfn(0,size_variation)
		svar = sign(svar) * fposmod(abs(svar),2*size_variation)
		aster.radius = mean_size * 2**svar
		aster.noise.seed = randi()
		aster.mass = (aster.radius/50)**2
		await aster.generate()
		tform = Transform2D(randf()*TAU, Util.current_camera_pos() + 
			Vector2.from_angle(randf()*TAU) * sqrt(randf()) * ((spawn_distance+despawn_distance)/2 + aster.radius))
	
	aster.transform = tform
	add_child.call_deferred(aster)
	await aster.tree_entered
	
	if(motion_target_radius<0):
		aster.apply_central_impulse(Vector2.from_angle(randf()*TAU) * max_linear_momentum * (2**randfn(0,1)))
	else:
		var target:Vector2 = Vector2.from_angle(randf()*TAU)*sqrt(randf())*motion_target_radius + Util.current_camera_pos()
		var momentum:Vector2 = (target - aster.position).normalized() * max_linear_momentum * (2**randfn(0,1))
		aster.apply_central_impulse(momentum)
		
	aster.apply_torque_impulse(randfn(-1,1) * max_angular_momentum * (2**randfn(0,1)))
