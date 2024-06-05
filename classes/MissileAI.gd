class_name MissileAI
extends AI

func _control_level()->int:
	return VELOCITY

func _update()->void:
	
	var facing:Vector2 = Vector2.from_angle(global_rotation)
	linear_velocity = linear_velocity.project(facing) + linear_velocity.project(facing.orthogonal())*(1-get_physics_process_delta_time()*4)
	linear_velocity += facing * max_linear_thrust * get_physics_process_delta_time()
	linear_velocity = linear_velocity.limit_length(max_linear_speed)
	
	var to_target:Vector2 = target_position - global_position
	var facing_to_target:Vector2 = Vector2.from_angle(global_rotation-to_target.angle())
	if(facing.dot(to_target)<0):
		angular_velocity = sign(angle_difference(global_rotation,to_target.angle())) * max_angular_speed
	elif(is_equal_approx(0,facing_to_target.y)):
		angular_velocity=0
	else:
		var rot_center:Vector2 = (global_position+target_position + to_target.orthogonal()*facing_to_target.x/facing_to_target.y)/2
		if(debug_draw):
			_draw_calls.push_back({'type':'arc','position':rot_center,'radius':(rot_center-global_position).length(),'color':Color(0,0,1),'global':true})
		angular_velocity = -sign((rot_center-global_position).dot(facing.orthogonal())) * linear_velocity.length()/(rot_center-global_position).length()
	
	angular_velocity = clamp(angular_velocity*2, -max_angular_speed, max_angular_speed)
	linear_velocity = await make_velocity_safe(linear_velocity)
		
