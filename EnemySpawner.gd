extends Node

## Scales how fast enemies spawn
@export var spawn_rate:float = 1
## Soft maximum total point_value of spawned enemies currently alive
@export var target_points:float = 10
## Minimum distance from player to spawn enemies
@export var min_spawn_distance:float = sqrt(2)*1024
## Maximum distance from player to spawn enemies
@export var max_spawn_distance:float = 2048

## Enemy types to spawn. Each scene's root must have a script extending the Enemy class
@export var enemy_list:Array[PackedScene]

## Prints spawns to console, for debugging
@export var print_spawns:bool = false


# internal values for helping the spawn algorithm
# keys are enemy scenes, values are weights
var spawn_list:Dictionary
var total_weight_in_list:float

func _ready()->void:
	spawn_list = {}
	total_weight_in_list = 0
	for scene:PackedScene in enemy_list:
		var enemy:Enemy = scene.instantiate()
		var weight:float = 100 / (enemy.point_value * enemy.rarity)
		enemy.queue_free()
		spawn_list[scene] = weight
		total_weight_in_list += weight

func _enter_tree()->void:
	Performance.add_custom_monitor('Enemy Points',get_total_enemy_points)

func _exit_tree() -> void:
	Performance.remove_custom_monitor('Enemy Points')

func _physics_process(delta: float) -> void:
	var spawn_chance:float = delta * spawn_rate * (target_points-get_total_enemy_points())/target_points
	if(randf() < spawn_chance):
		spawn_an_enemy()

func spawn_an_enemy()->void:
	var players:Array = get_tree().get_nodes_in_group('Players')
	if(players.is_empty()):
		return
	
	# pick a random scene from spawn list, weighted by spawn_rate
	var choice:float = randf() * total_weight_in_list
	var chosen_scene:PackedScene
	for scene:PackedScene in spawn_list:
		choice-=spawn_list[scene]
		if(choice<=0):
			chosen_scene=scene
			break
	var enemy:Enemy = chosen_scene.instantiate()
	# it might somehow trigger a collision if it's at 0,0, so start it off really far away
	enemy.position = Vector2(1000000,1000000)
	add_child(enemy)
	
	var point_found:bool=false
	var candidate:Transform2D
	var attempts:int = 0
	const max_attempts:int = 3
	while(!point_found):
		attempts += 1
		if(attempts>max_attempts):
			push_error("Failed to place an enemy after ",max_attempts," attempts")
			enemy.queue_free()
			return
		
		#pick a random position and rotation
		var theta:float = randf()*TAU
		var p_rel:Vector2 = Vector2(cos(theta),sin(theta)) * randf_range(min_spawn_distance,max_spawn_distance)
		candidate = Transform2D(randf()*TAU,players.pick_random().position+p_rel)
		
		#check for collisions
		if(enemy.test_move(candidate,Vector2.ZERO)):
			continue
		
		#check if it's too close to a player
		point_found = true
		for player:Player in players:
			var dist:float = (player.position-candidate.origin).length()
			if(dist<min_spawn_distance):
				point_found=false
				break
	
	enemy.transform = candidate
	
	if(print_spawns):
		print(("[{time}] Spawned a {name} at {loc}\n"+
				"\tTook {attempts} attempts\n"+
				"\tChance was {weight}/{tot_weight} ({pct}%)\n").format({
			'time':Time.get_time_string_from_system(),
			'name':chosen_scene.get_state().get_node_name(0),
			'loc':'%.v'%enemy.position,
			'attempts':attempts,
			'weight':'%.2f'%(spawn_list[chosen_scene]),
			'tot_weight':'%.2f'%(total_weight_in_list),
			'pct':'%.2f'%(100*spawn_list[chosen_scene]/total_weight_in_list)}))

func get_total_enemy_points()->float:
	var enemies:Array = get_tree().get_nodes_in_group('Enemies')
	var total:float = 0
	for enemy:Enemy in enemies:
		total += enemy.point_value
	return total
