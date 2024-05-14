class_name Player
extends Actor

## Approximate radius at which to collect pickups
@export var pickup_magnet:float = 256
## Total value of all enemies this player has killed
var score:float:
	set(to):
		score=to
		score_changed.emit(score)

signal score_changed(to:float)

func _ready()->void:
	add_ability(load("res://abilities/light_cannon/light_cannon.tscn").instantiate())

func get_muzzle_position()->Vector2:
	return $Muzzle.global_position
func get_muzzle_direction()->Vector2:
	return Vector2.UP.rotated($Muzzle.global_rotation)

var _add_ability_queue:Array[PlayerAbility]
var _is_adding_ability:bool = false

## Adds an ability to the player. If the ability conflicts with an existing ability, the player
## is given the option to keep the old one or switch to the new one.
func add_ability(ability:PlayerAbility):
	if(_is_adding_ability):
		# since _add_ability is async, use a queue to make sure the next call waits for the last to finish
		_add_ability_queue.push_back(ability)
	else:
		_is_adding_ability=true
		await _add_ability(ability)
		_is_adding_ability=false
		if(!_add_ability_queue.is_empty()):
			var next:PlayerAbility = _add_ability_queue.pop_front()
			add_ability(next)

func _add_ability(ability:PlayerAbility):
	if(modifiers.has(ability.mod_name)):
		if(modifiers[ability.mod_name] is PlayerAbility && 
			modifiers[ability.mod_name].ability_name==ability.ability_name):
			# if the existing ability is the same thing, just refresh it without asking
			add_modifier(ability)
		else:
			var uilayer:CanvasLayer = get_tree().get_first_node_in_group('UILayer')
			var chooser:Control = load('res://ui/ability_choice_screen.tscn').instantiate()
			chooser.left_ability = modifiers[ability.mod_name]
			chooser.right_ability = ability
			uilayer.add_child(chooser)
			var selected:PlayerAbility = await chooser.select_finished
			if(selected==ability):
				add_modifier(ability)
			else:
				ability.queue_free()
	else:
		# if player doesn't have this type of ability, just add it
		add_modifier(ability)

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
	angular_target = rotation_input * max_angular_speed
	
	if(Input.is_action_pressed('forward')):
		linear_target = global_transform.basis_xform(Vector2.UP).normalized() * max_linear_thrust
		$Interpolator/RocketParticles.emitting=true
		$Interpolator/RocketParticles.process_material.set_shader_parameter('base_velocity',linear_velocity)
	else:
		linear_target = Vector2.ZERO
		$Interpolator/RocketParticles.emitting=false

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
