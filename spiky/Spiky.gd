class_name Spiky
extends Actor

## Damage dealt when colliding with player
@export var contact_damage:float = 3

func find_target()->Player:
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

func _physics_process(delta: float) -> void:
	
	var move_dir:Vector2
	var target:Player = find_target()
	if(target==null):
		if(velocity==Vector2.ZERO):
			move_dir=Vector2.ZERO
		else:
			move_dir=-velocity.normalized()
	else:
		move_dir=(target.position-position).normalized()
	
	if(move_dir!=Vector2.ZERO):
		rotate(sin(move_dir.angle_to(velocity)) * rotation_speed * delta)
	velocity += move_dir * acceleration * delta
	
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
			
			var self_damage:Damage = Damage.new()
			self_damage.amount = 1000
			self_damage.position = position
			self_damage.source = self
			take_damage(self_damage)
