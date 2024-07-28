class_name EnemySpawner
extends Node

## Scales how fast enemies spawn
@export var spawn_rate:float = 1
## Soft maximum total point_value of spawned enemies currently alive
@export var target_points:float = 10

const enemy_list:SceneList = preload("res://enemies/common_enemy_list.tres")

## Toggles all enemy spawning
@export var enabled:bool = true

static func get_weight(scene:PackedScene)->float:
	var spawnable:bool = Util.get_scene_prop(scene, &'spawnable', true)
	var point_value:float = Util.get_scene_prop(scene, &'point_value', 1)
	var rarity:float = Util.get_scene_prop(scene, &'rarity', 1)
	return 100.0/(point_value*rarity) if spawnable else 0

func select_random_enemy()->PackedScene:
	return enemy_list.pick_random(get_weight)

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
	spawn(select_random_enemy())

func spawn(scene:PackedScene)->Enemy:
	var enemy:Enemy = scene.instantiate()
	var locator:Callable = func()->Transform2D:
		return Transform2D(randf()*TAU, Util.current_camera_pos() + 
			Vector2.from_angle(randf()*TAU) * randf_range(enemy.min_spawn_distance,enemy.max_spawn_distance))
	
	if(!Util.attempt_place_node(enemy,self,locator,5)):
		push_error("Failed to place an enemy after 5 attempts")
		enemy.queue_free()
		return null
	else:
		return enemy

func get_total_enemy_points()->float:
	var enemies:Array = get_tree().get_nodes_in_group('Enemies')
	var total:float = 0
	for enemy:Enemy in enemies:
		total += enemy.point_value
	return total
