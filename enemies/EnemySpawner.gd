extends Node

## Scales how fast enemies spawn
@export var spawn_rate:float = 1
## Soft maximum total point_value of spawned enemies currently alive
@export var target_points:float = 10

## Enemy types to spawn. Each scene's root must have a script extending the Enemy class
@export var enemy_list:Array[PackedScene]

## Toggles all enemy spawning
@export var enabled:bool = true

## Internal list of everything that can spawn. Format is 
## [code]{StringName:{'scene':PackedScene,'weight':float}}[/code]
var spawn_list:Dictionary
var total_weight_in_list:float

func _ready()->void:
	spawn_list = {}
	total_weight_in_list = 0
	for scene:PackedScene in enemy_list:
		var enemy:Enemy = scene.instantiate()
		var weight:float = 100 / (enemy.point_value * enemy.rarity)
		spawn_list[StringName(enemy.name)] = {'scene':scene,'weight':weight}
		total_weight_in_list += weight
		enemy.queue_free()

func _enter_tree()->void:
	Performance.add_custom_monitor('Enemy Points',get_total_enemy_points)

func _exit_tree() -> void:
	Performance.remove_custom_monitor('Enemy Points')

func _physics_process(delta: float) -> void:
	if(!enabled):
		return
	var spawn_chance:float = delta * spawn_rate * (target_points-get_total_enemy_points())/target_points
	if(randf() < spawn_chance):
		spawn_an_enemy()

func spawn_an_enemy()->void:
	var players:Array = get_tree().get_nodes_in_group('Players')
	if(players.is_empty()):
		return
	
	# pick a random scene from spawn list, weighted by spawn_rate
	var choice:float = randf() * total_weight_in_list
	var chosen:StringName
	for ename:StringName in spawn_list:
		choice -= spawn_list[ename].weight
		if(choice<=0):
			chosen=ename
			break
	
	spawn(chosen)

func spawn(ename:StringName)->void:
	var enemy:Enemy = spawn_list[ename].scene.instantiate()
	var campos:Vector2 = get_viewport().get_camera_2d().get_screen_center_position()
	var locator:Callable = func()->Transform2D:
		return Transform2D(randf()*TAU, campos + 
			Vector2.from_angle(randf()*TAU) * randf_range(enemy.min_spawn_distance,enemy.max_spawn_distance))
	
	if(!Util.attempt_place_actor(enemy,self,locator,5)):
		push_error("Failed to place an enemy after 5 attempts")
		enemy.queue_free()

func get_total_enemy_points()->float:
	var enemies:Array = get_tree().get_nodes_in_group('Enemies')
	var total:float = 0
	for enemy:Enemy in enemies:
		total += enemy.point_value
	return total
