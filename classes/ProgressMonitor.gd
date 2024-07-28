class_name ProgressMonitor
extends Node

enum{COMMON_UPGRADE, MOVEMENT_ABILITY, ATTACK_ABILITY, WEAPON, BOSS}
const progression_cycle:PackedInt64Array = [
	COMMON_UPGRADE, MOVEMENT_ABILITY,
	COMMON_UPGRADE, ATTACK_ABILITY,
	COMMON_UPGRADE, WEAPON,
	COMMON_UPGRADE, BOSS]

var progression_stage:int = 0

## The initial increase in score necessary to progress to the next cycle stage.
@export var score_req_base:float = 100
## Increase in score requirement each time a stage is passed.
@export var score_req_growth:float = 20

## The (absolute) score needed to progress to the next stage.
var score_req:float

## The currently spawned boss that must be killed to reach the next stage.
var current_boss:Enemy

var player:Player
var enemy_spawner:EnemySpawner
var pickup_spawner:PickupSpawner
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_spawner = get_tree().current_scene.find_child('EnemySpawner',true,false)
	pickup_spawner = get_tree().current_scene.find_child('PickupSpawner',true,false)
	player = get_tree().get_first_node_in_group(&'Players')
	player.kill.connect(_on_player_kill)

func get_current_stage()->int:
	return progression_cycle[progression_stage%progression_cycle.size()] 

func _on_player_kill(damage:Damage)->void:
	if(player.score>score_req && get_current_stage()!=BOSS):
		match get_current_stage():
			COMMON_UPGRADE:
				pass
			MOVEMENT_ABILITY:
				var pickup:AbilityPickup = preload('res://pickups/ability_pickup.tscn').instantiate()
				pickup.type = PlayerAbility.MOVEMENT
				pickup_spawner.drop(pickup, damage.target)
				score_req += score_req_base + score_req_growth*progression_stage
			ATTACK_ABILITY:
				var pickup:AbilityPickup = preload('res://pickups/ability_pickup.tscn').instantiate()
				pickup.type = PlayerAbility.ATTACK
				pickup_spawner.drop(pickup, damage.target)
				score_req += score_req_base + score_req_growth*progression_stage
			WEAPON:
				var pickup:AbilityPickup = preload('res://pickups/ability_pickup.tscn').instantiate()
				pickup.type = PlayerAbility.WEAPON
				pickup_spawner.drop(pickup, damage.target)
				score_req += score_req_base + score_req_growth*progression_stage
		progression_stage += 1
		if(get_current_stage()==BOSS):
			current_boss = enemy_spawner.spawn(preload('res://enemies/broadside/broadside.tscn'))
			current_boss.death.connect(_on_boss_death)

func _on_boss_death(damage:Damage)->void:
	# reset score requirement so that multiple stages can't be passed at once
	score_req = player.score + score_req_base + score_req_growth*progression_stage
	current_boss = null
	progression_stage += 1
	if(get_current_stage()==BOSS):
		current_boss = enemy_spawner.spawn(preload('res://enemies/broadside/broadside.tscn'))
		current_boss.death.connect(_on_boss_death)
