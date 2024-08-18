class_name Player
extends Actor

## Approximate radius at which to collect pickups
const pickup_magnet:float = 256

const max_rotation_speed:float = 10
const max_linear_speed:float = 800
const max_thrust:float = 250
const max_torque:float = 7.75

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

signal new_upgrade(upgrade:Upgrade)
signal added_upgrade(upgrade:Upgrade)

## Map of ability type (see PlayerAbility.gd) to ability nodes
var abilities:Dictionary

## 0-1 parameter for determining volume of the rocket
var _rocket_volume:float = 0

func add_ability(ability:PlayerAbility)->void:
	
	if(abilities.has(ability.type) && abilities[ability.type].ability_name == ability.ability_name):
		# if the new ability is the same as the one already possessed, ignore it
		ability.queue_free()
		return
	
	new_ability.emit(ability)
	var uilayer:CanvasLayer = get_tree().get_first_node_in_group('UILayer')
	var ability_choice_screen:AbilityChoiceScreen = preload('res://ui/ability_choice_screen.tscn').instantiate()
	uilayer.add_child(ability_choice_screen)
	ability_choice_screen.add_ability(ability)
	if(abilities.has(ability.type)):
		ability_choice_screen.add_ability(abilities[ability.type])
	ability_choice_screen.begin_selection()
	var selected:PlayerAbility = await ability_choice_screen.select_finished
	ability_choice_screen=null
	
	if(selected.is_inside_tree()):
		ability.queue_free()
	else:
		if(abilities.has(ability.type)):
			remove_ability(abilities[ability.type])
		ability.ability_initialized=true
		abilities[ability.type]=ability
		add_child(ability)
		added_ability.emit(ability)

func add_upgrade(options:Array[Upgrade])->void:
	for up:Upgrade in options:
		new_upgrade.emit(up)
	var uilayer:CanvasLayer = get_tree().get_first_node_in_group('UILayer')
	var upgrade_choice_screen:UpgradeChoiceScreen = preload('res://ui/upgrade_choice_screen.tscn').instantiate()
	uilayer.add_child(upgrade_choice_screen)
	for up:Upgrade in options:
		upgrade_choice_screen.add_upgrade(up)
	upgrade_choice_screen.begin_selection()
	var selected:Upgrade = await upgrade_choice_screen.select_finished
	
	for up:Upgrade in options:
		if(up!=selected):
			up.queue_free()
	add_child(selected)
	added_upgrade.emit(selected)

func remove_ability(ability:PlayerAbility)->void:
	assert(ability.is_inside_tree())
	assert(ability.get_parent()==self)
	assert(abilities[ability.type]==ability)
	abilities.erase(ability.type)
	removed_ability.emit(ability)
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
	if(rotation_input==0 && abs(self.angular_velocity)<max_torque*delta):
		self.angular_velocity = 0
	else:
		self.angular_velocity += -sign(self.angular_velocity - rotation_input*max_rotation_speed)*max_torque*delta
	
	if(Input.is_action_pressed('forward')):
		$'.'.apply_force(global_transform.basis_xform(Vector2.UP).normalized() * max_thrust)
		$Interpolator/RocketParticles.emitting=true
		$Interpolator/RocketParticles.process_material.set_shader_parameter('base_velocity',self.linear_velocity)
		_rocket_volume = clamp(_rocket_volume + delta*10, 0, 1)
	else:
		_rocket_volume = clamp(_rocket_volume - delta*10, 0, 1)
		$Interpolator/RocketParticles.emitting=false
	$RocketSound.volume_db = remap(_rocket_volume, 0, 1, -40, -10)
	
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
