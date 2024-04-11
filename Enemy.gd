class_name Enemy
extends Actor

## Damage dealt to player on contact
@export var contact_damage:float = 1
## Whether or not the enemy should die when dealing contact damage
@export var contact_suicide:bool = false

## How strong this enemy is; used for spawning and scoring
@export var point_value:float = 1
## Scales point_value for spawning purposes; higher rarity or point_value decreases spawn frequency
@export var rarity:float = 1
## Maximum distance from a player before despawning
@export var despawn_distance:float = 4096

func find_nearest_player()->Player:
	var players:Array[Node] = get_tree().get_nodes_in_group('Players')
	if(players.is_empty()):
		return null
	var closest_player:Player = players[0]
	var closest_player_dsqr:float = (closest_player.position-position).length_squared()
	for player:Player in players:
		var dsqr:float = (player.position-position).length_squared()
		if(dsqr<closest_player_dsqr):
			closest_player=player
			closest_player_dsqr=dsqr
	return closest_player

# NB: MUST be called by subclass if the subclass implements _physics_process
func _physics_process(delta: float) -> void:
	
	super(delta)
	
	for coll_idx:int in range(get_slide_collision_count()):
		var collision:KinematicCollision2D = get_slide_collision(coll_idx)
		if(collision.get_collider() is Player):
			var damage:Damage = Damage.new()
			damage.amount = contact_damage
			damage.position = collision.get_position()
			damage.direction = collision.get_normal()
			damage.source = self
			collision.get_collider().take_damage(damage)
			
			if(contact_suicide):
				var self_damage:Damage = Damage.new()
				self_damage.amount = max_health
				self_damage.position = position
				self_damage.source = self
				take_damage(self_damage)
	
	var nearest_player:Player = find_nearest_player()
	if(nearest_player!=null && (nearest_player.position-position).length()>despawn_distance):
		queue_free()
