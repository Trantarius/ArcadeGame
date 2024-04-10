class_name Player
extends CharacterBody2D

## Highest permitted linear speed
@export var max_speed:float = 500

## Linear acceleration applied when 'forward' is held
@export var acceleration:float = 100

## Rotation speed (in radians/second) when 'left' or 'right' is held
@export var rotation_speed:float = 3

# position the previous frame, used for correcting velocity
var old_position:Vector2

func _enter_tree()->void:
	old_position=position

func _physics_process(delta: float) -> void:
	
	# since 'left' and 'right' are buttons, this will always be -1, 0, or 1
	var rotation_input:float = Input.get_axis('left','right')
	rotate(rotation_input * delta * rotation_speed)
	
	if(Input.is_action_pressed('forward')):
		velocity += global_transform.basis_xform(Vector2.UP).normalized() * acceleration * delta
	
	if(velocity.length() > max_speed):
		velocity = velocity.normalized() * max_speed

	move_and_slide()
	
	var actual_motion:Vector2 = (position-old_position)
	var am_lsqr:float = actual_motion.length_squared()
	if(am_lsqr>0.0001):
		# project the velocity onto the actual movement direction
		velocity = actual_motion * max(0,velocity.dot(actual_motion)) / am_lsqr
	
	old_position=position
