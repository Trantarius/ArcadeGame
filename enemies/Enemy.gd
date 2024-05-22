class_name Enemy
extends Actor

## Damage dealt to player on contact (requires contact_monitor to be enabled)
@export var contact_damage:float = 1
## Whether or not the enemy should die when dealing contact damage
@export var contact_suicide:bool = false

## How strong this enemy is; used for spawning and scoring
@export var point_value:float = 1
## Scales point_value for spawning purposes; higher rarity or point_value decreases spawn frequency
@export var rarity:float = 1
## Minimum distance from the player at spawn
@export var min_spawn_distance:float = 2000
## Maximum distance from the player at spawn
@export var max_spawn_distance:float = 5000
## Maximum distance from a player before despawning
@export var despawn_distance:float = 8000
## Distance at which to show up on radar (<0 to disable)
@export var radar_distance:float = -1

func _init() -> void:
	super()
	add_to_group(&'Enemies')

func _physics_process(_delta: float) -> void:
	
	var nearest_player:Player = Player.find_nearest_player(position)
	if(nearest_player!=null && (nearest_player.position-position).length()>despawn_distance):
		queue_free()
