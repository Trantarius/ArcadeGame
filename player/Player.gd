class_name Player
extends Actor

## Bullets shot per second while holding the 'shoot' button
@export var fire_rate:float
## Allows for continuous shooting without holding the 'shoot' button
@export var auto_fire:bool
## Approximate radius at which to collect pickups
@export var pickup_magnet:float = 256
## Time until the next shot can be taken
var shot_timer:float
## Total value of all enemies this player has killed
var score:float

var movement_ability:PlayerAbility:
	set(to):
		if(movement_ability!=to):
			var old:PlayerAbility = movement_ability
			movement_ability = to
			if(is_instance_valid(old)):
				remove_child(old)
			if(is_instance_valid(movement_ability)):
				add_child(movement_ability)
			ability_changed.emit(old,movement_ability)
			if(is_instance_valid(old)):
				old.queue_free()

signal ability_changed(from:PlayerAbility,to:PlayerAbility)

func _on_death(damage:Damage)->void:
	# ensure camera stays around after player dies
	$Camera2D.is_free=true
	$Camera2D.reparent(get_parent())

func _on_kill(damage:Damage)->void:
	if(damage.target is Enemy):
		score += damage.target.point_value

func _physics_process(delta: float) -> void:
	
	# since 'left' and 'right' are buttons, this will always be -1, 0, or 1
	var rotation_input:float = Input.get_axis('left','right')
	angular_target = rotation_input * max_angular_speed
	
	if(Input.is_action_pressed('forward')):
		linear_target = global_transform.basis_xform(Vector2.UP).normalized() * max_linear_thrust
		$Interpolator/RocketParticles.emitting=true
		$Interpolator/RocketParticles.process_material.set_shader_parameter('base_velocity',linear_velocity)
	else:
		linear_target = Vector2.ZERO
		$Interpolator/RocketParticles.emitting=false
	
	shot_timer-=delta
	if((Input.is_action_pressed('shoot')!=auto_fire) && shot_timer<=0):
		fire_bullet()
		shot_timer = 1.0/fire_rate

func fire_bullet()->void:
	var bullet:Projectile = preload("res://player/bullet.tscn").instantiate()
	bullet.position = position
	bullet.linear_velocity = 800 * global_transform.basis_xform(Vector2.UP).normalized() + linear_velocity
	bullet.source=self
	get_parent().add_child(bullet)


static func find_nearest_player(location:Vector2, max_dist:float=-1)->Player:
	var players:Array[Node] = Engine.get_main_loop().get_nodes_in_group('Players')
	var closest_player:Player = null
	var closest_player_dsqr:float = max_dist*max_dist if max_dist>0 else INF
	for player:Player in players:
		var dsqr:float = (player.position-location).length_squared()
		if(dsqr<closest_player_dsqr):
			closest_player=player
			closest_player_dsqr=dsqr
	return closest_player
