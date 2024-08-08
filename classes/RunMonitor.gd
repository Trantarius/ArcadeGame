class_name RunMonitor
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

var score:float
var run_start_time:int = 0
var events:Array[Dictionary]
var perf_data:Array[Dictionary]
var run_ended:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Client.try_connect_to(Client.host)
	enemy_spawner = get_tree().current_scene.find_child('EnemySpawner',true,false)
	pickup_spawner = get_tree().current_scene.find_child('PickupSpawner',true,false)
	player = get_tree().get_first_node_in_group(&'Players')
	player.kill.connect(_on_player_kill)
	player.death.connect(_on_player_death)
	player.new_ability.connect(_on_player_new_ability)
	player.added_ability.connect(_on_player_added_ability)
	player.removed_ability.connect(_on_player_removed_ability)
	player.new_upgrade.connect(_on_player_new_upgrade)
	player.added_upgrade.connect(_on_player_added_upgrade)
	score_req = score_req_base
	process_mode = Node.PROCESS_MODE_ALWAYS
	var perf_timer:Timer = Timer.new()
	add_child(perf_timer)
	perf_timer.timeout.connect(_update_perf_info)
	perf_timer.start(10)

func _update_perf_info()->void:
	perf_data.push_back({
		'fps': _worst_fps,
		'process': _worst_process,
		'physics': _worst_physics,
		'nav': _worst_nav
	})
	_worst_fps = INF
	_worst_physics = -INF
	_worst_process = -INF
	_worst_nav = -INF

var _worst_process:float = -INF
var _worst_physics:float = -INF
var _worst_fps:float = INF
var _worst_nav:float = -INF
func _process(_delta: float) -> void:
	_worst_process = max(_worst_process, Performance.get_monitor(Performance.TIME_PROCESS))
	_worst_physics = max(_worst_physics, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
	_worst_nav = max(_worst_nav, Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS))
	_worst_fps = min(_worst_fps, Performance.get_monitor(Performance.TIME_FPS))

func get_current_stage()->int:
	return progression_cycle[progression_stage%progression_cycle.size()] 

func identify(obj:Object)->String:
	if(!is_instance_valid(obj)):
		return '<null>'
	if(obj is Node && !obj.scene_file_path.is_empty()):
		return '<'+obj.scene_file_path+'>'
	if(obj is Resource):
		return '<'+obj.resource_path+'>'
	if(is_instance_valid(obj.get_script())):
		return '<'+obj.get_script().resource_path+'>'
	return str(obj)

func source_trace(obj:Object)->String:
	var trace:String = identify(obj)
	if(&'source' in obj && is_instance_valid(obj.source)):
		trace += ' from ' + source_trace(obj.source)
	return trace

func end_run()->void:
	if(run_ended):
		return
	run_ended=true
	print("run end")
	events.push_back({'event':'run_end','time': Time.get_ticks_msec()-run_start_time})
	GlobalMonitor.record_run(events, score, perf_data)

func _exit_tree() -> void:
	print("exit tree")

func _notification(what: int) -> void:
	if((what==NOTIFICATION_EXIT_TREE || what==NOTIFICATION_WM_CLOSE_REQUEST) && is_instance_valid(player)):
		end_run()

func _on_player_kill(damage:Damage)->void:
	
	if(damage.target is Enemy):
		score += damage.target.point_value
	
	events.push_back({
		'event':'player_kill',
		'target':identify(damage.target),
		'method':source_trace(damage.source),
		'time': Time.get_ticks_msec()-run_start_time
	})
	
	if(player.score>score_req && get_current_stage()!=BOSS):
		match get_current_stage():
			COMMON_UPGRADE:
				var pickup:Pickup = preload('res://pickups/common_upgrade_pickup.tscn').instantiate()
				pickup_spawner.drop(pickup, damage.target)
				score_req += score_req_base + score_req_growth*progression_stage
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

func _on_player_death(damage:Damage)->void:
	events.push_back({
		'event':'player_death',
		'attacker':identify(damage.attacker),
		'method':source_trace(damage.source),
		'time': Time.get_ticks_msec()-run_start_time
	})
	end_run()

func _on_player_new_ability(ability:PlayerAbility)->void:
	events.push_back({
		'event':'player_new_ability',
		'ability_name':ability.ability_name,
		'time': Time.get_ticks_msec()-run_start_time
	})

func _on_player_added_ability(ability:PlayerAbility)->void:
	events.push_back({
		'event':'player_added_ability',
		'ability_name':ability.ability_name,
		'time': Time.get_ticks_msec()-run_start_time
	})

func _on_player_removed_ability(ability:PlayerAbility)->void:
	events.push_back({
		'event':'player_removed_ability',
		'ability_name':ability.ability_name,
		'time': Time.get_ticks_msec()-run_start_time
	})

func _on_player_new_upgrade(upgrade:Upgrade)->void:
	events.push_back({
		'event':'player_new_upgrade',
		'upgrade_name':upgrade.upgrade_name,
		'time': Time.get_ticks_msec()-run_start_time
	})

func _on_player_added_upgrade(upgrade:Upgrade)->void:
	events.push_back({
		'event':'player_added_upgrade',
		'upgrade_name':upgrade.upgrade_name,
		'time': Time.get_ticks_msec()-run_start_time
	})
