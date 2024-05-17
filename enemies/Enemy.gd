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
@export var min_spawn_dist:float = 2000
## Maximum distance from the player at spawn
@export var max_spawn_dist:float = 5000
## Maximum distance from a player before despawning
@export var despawn_distance:float = 8000

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	super(state)
	
	if(health<=0):
		return
	
	for coll_idx:int in range(state.get_contact_count()):
		if(state.get_contact_collider_object(coll_idx) is Player):
			var damage:Damage = Damage.new()
			damage.amount = contact_damage
			damage.position = state.get_contact_collider_position(coll_idx)
			damage.direction = state.transform.basis_xform(state.get_contact_local_normal(coll_idx))
			damage.source = self
			damage.attacker = self
			state.get_contact_collider_object(coll_idx).take_damage(damage)
			
			if(contact_suicide):
				var self_damage:Damage = Damage.new()
				self_damage.amount = max_health
				self_damage.position = position
				self_damage.source = self
				self_damage.attacker = self
				self_damage.silent = true
				take_damage(self_damage)
				break
	
	var nearest_player:Player = Player.find_nearest_player(position)
	if(nearest_player!=null && (nearest_player.position-position).length()>despawn_distance):
		queue_free()
