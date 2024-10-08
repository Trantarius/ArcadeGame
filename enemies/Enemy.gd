class_name Enemy
extends Actor

## How strong this enemy is, used for scoring.
@export var point_value:Stat
## Scales how often the enemy will randomly spawn, if allowed. Higher rarity decreases spawn chance. 
@export var rarity:float = 1
## Enables/disables random spawning from EnemySpawner.
@export var spawnable:bool = true

## Minimum distance from the player at spawn
@export var min_spawn_distance:float = 2000
## Maximum distance from the player at spawn
@export var max_spawn_distance:float = 5000
## Maximum distance from a player before despawning. <0 to disable.
@export var despawn_distance:float = 8000
## Distance at which to show up on radar (<0 to disable)
@export var radar_distance:float = -1

func _init() -> void:
	super()
	add_to_group(&'Enemies')

func _physics_process(_delta: float) -> void:
	
	var nearest_player:Player = Player.find_nearest_player(position)
	if(despawn_distance>0 && nearest_player!=null && (nearest_player.position-position).length()>despawn_distance):
		queue_free()
