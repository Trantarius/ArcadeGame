class_name BallisticAI
extends AI

@export var brake:float = 1

func _update()->void:
	
	force = Ballistics.find_thrust_to_position(global_position,linear_velocity, Vector2.ZERO, target_position, 
		target_velocity, target_acceleration, max_linear_thrust,brake)
	
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
	
	
