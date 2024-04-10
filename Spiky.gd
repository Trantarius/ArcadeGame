class_name Spiky
extends CharacterBody2D

## Highest permitted linear speed
@export var max_speed:float = 300

## Linear acceleration towards the player
@export var acceleration:float = 50

## Maximum rotation speed (purely cosmetic)
@export var rotation_speed:float = 3

## Portion of velocity decayed per second
@export var velocity_damp:float = 0.5

# position the previous frame, used for correcting velocity
var old_position:Vector2

func _enter_tree()->void:
	old_position=position

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
	velocity *= 1 - velocity_damp * delta
	
	if(velocity.length() > max_speed):
		velocity = velocity.normalized() * max_speed

	move_and_slide()
	
	var actual_motion:Vector2 = (position-old_position)
	var am_lsqr:float = actual_motion.length_squared()
	if(am_lsqr>0.0001):
		# project the velocity onto the actual movement direction
		velocity = actual_motion * max(0,velocity.dot(actual_motion)) / am_lsqr
	
	old_position=position
