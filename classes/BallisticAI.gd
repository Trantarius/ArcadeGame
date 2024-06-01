class_name BallisticAI
extends AI

func _update()->void:
	
	var relative_position:Vector2 = global_position - target_position
	var relative_velocity:Vector2 = linear_velocity - target_velocity
	
	var brake_time:float = relative_velocity.length()/max_linear_thrust
	var brake_pos:Vector2 = relative_position + relative_velocity * brake_time/2
	var desired_speed:float = sqrt(2*relative_position.length()*max_linear_thrust)
	var desired_velocity:Vector2 = desired_speed * -brake_pos.normalized() + target_velocity
	
	desired_velocity = (desired_velocity.limit_length(max_linear_speed))
	force += (desired_velocity-linear_velocity).normalized()*max_linear_thrust
	
	var safe_vel:Vector2 = await make_velocity_safe(linear_velocity)
	force += (safe_vel-linear_velocity)/get_physics_process_delta_time()
	
	force = force.limit_length(max_linear_thrust)
	force += linear_velocity
	force = force.limit_length(max_linear_speed)
	force -= linear_velocity
	
	torque = clamp(torque, -max_angular_thrust, max_angular_thrust)
	torque += angular_velocity
	torque = clamp(torque,-max_angular_speed,max_angular_speed)
	torque -= angular_velocity
	
	
