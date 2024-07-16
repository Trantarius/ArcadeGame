class_name Player
extends Actor

## Approximate radius at which to collect pickups
@export var pickup_magnet:float = 256

@export var max_rotation_speed:float
@export var max_linear_speed:float
@export var max_thrust:float
@export var max_torque:float

## Total value of all enemies this player has killed
var score:float:
	set(to):
		score=to
		score_changed.emit(score)

signal score_changed(to:float)

# emitting when a new ability is considered (before choice screen)
signal new_ability(ability:PlayerAbility)

# emitted when an ability is finalized (after choice screen)
signal added_ability(ability:PlayerAbility)
signal removed_ability(ability:PlayerAbility)

var abilities:Dictionary

func add_ability(ability:PlayerAbility)->void:
	add_child(ability)

func remove_ability(ability:PlayerAbility)->void:
	assert(ability.is_inside_tree())
	assert(ability.get_parent()==self)
	assert(abilities[ability.type]==ability)
	removed_ability.emit(ability)
	abilities.erase(ability.type)
	ability.queue_free()

func get_muzzle_position()->Vector2:
	return $Interpolator/Muzzle.global_position
func get_muzzle_direction()->Vector2:
	return Vector2.UP.rotated($Interpolator/Muzzle.global_rotation)

func _on_death(_damage:Damage)->void:
	# ensure camera stays around after player dies
	$Camera2D.is_free=true
	$Camera2D.reparent(get_parent())

func _on_kill(damage:Damage)->void:
	if(damage.target is Enemy):
		score += damage.target.point_value

func _physics_process(delta: float) -> void:
	
	# since 'left' and 'right' are buttons, this will always be -1, 0, or 1
	var rotation_input:float = Input.get_axis('left','right')
	$'.'.apply_torque(-sign(self.angular_velocity - rotation_input*max_rotation_speed)*max_torque)
	
	if(Input.is_action_pressed('forward')):
		$'.'.apply_force(global_transform.basis_xform(Vector2.UP).normalized() * max_thrust)
		$Interpolator/RocketParticles.emitting=true
		$Interpolator/RocketParticles.process_material.set_shader_parameter('base_velocity',self.linear_velocity)
	else:
		$Interpolator/RocketParticles.emitting=false
	
	$'.'.linear_velocity = $'.'.linear_velocity.limit_length(max_linear_speed)

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
