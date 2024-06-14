class_name BallisticAI
extends AI

@export var brake:float = 1

func _update(delta:float)->void:
	
	var force:Vector2 = Ballistics.find_thrust_to_position(global_position,linear_velocity, Vector2.ZERO, target_position, 
		target_velocity, Vector2.ZERO, max_linear_thrust,brake)
	
	force = force.limit_length(max_linear_thrust)
	force += linear_velocity
	force = force.limit_length(max_linear_speed)
	force -= linear_velocity
	
	linear_velocity += force*delta
	
	linear_velocity = await make_velocity_safe(linear_velocity)
	
	
