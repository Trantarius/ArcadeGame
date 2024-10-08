class_name EnemySpawner
extends Node

## Scales how fast enemies spawn
@export var spawn_rate:float = 1

const enemy_list:SceneList = preload("res://enemies/common_enemy_list.tres")

## Toggles all enemy spawning
@export var enabled:bool = true

static func get_weight(scene:PackedScene)->float:
	var spawnable:bool = Util.get_scene_prop(scene, &'spawnable', true)
	var rarity:float = Util.get_scene_prop(scene, &'rarity', 1)
	return 100.0/(rarity) if spawnable else 0

func select_random_enemy()->PackedScene:
	return enemy_list.pick_random(get_weight)

func _enter_tree()->void:
	Performance.add_custom_monitor('Enemy Points',get_total_enemy_points)

func _exit_tree() -> void:
	Performance.remove_custom_monitor('Enemy Points')

func _physics_process(delta: float) -> void:
	if(!enabled):
		return
	var spawn_chance:float = delta * spawn_rate / get_total_enemy_points()
	if(randf() < spawn_chance):
		spawn_an_enemy()

func spawn_an_enemy()->void:
	spawn(select_random_enemy())

func spawn(scene:PackedScene)->Enemy:
	var enemy:Enemy = scene.instantiate()
	var locator:Callable = func()->Transform2D:
		return Transform2D(randf()*TAU, Util.current_camera_pos() + 
			Vector2.from_angle(randf()*TAU) * randf_range(enemy.min_spawn_distance,enemy.max_spawn_distance))
	
	var tform:Transform2D = locator.call()
	var attempts:int = 1
	while(!Util.does_node_fit(enemy,tform)):
		if(attempts%10==0):
			await get_tree().process_frame
		tform = locator.call()
		attempts += 1
	if(attempts>10):
		push_warning('enemy took '+str(attempts)+' attempts to place')
	enemy.transform = tform
	get_tree().current_scene.add_child.bind(enemy).call_deferred()
	await enemy.ready
	return enemy

func get_total_enemy_points()->float:
	var enemies:Array = get_tree().get_nodes_in_group('Enemies')
	var total:float = 0
	for enemy:Enemy in enemies:
		total += enemy.point_value.get_value()
	return total
