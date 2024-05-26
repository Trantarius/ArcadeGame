class_name Ballistics
extends Node

## Finds a ballistic trajectory from the current position/velocity/acceleration to the target position/velocity/acceleration.
## Returns the additional acceleration needed to move along that trajectory. This additional acceleration will not
## exceed [param max_thrust]. [param brake] determines to what degree it is desired to reach the target velocity once
## at the target position
static func find_thrust_to_position(position:Vector2, velocity:Vector2, acceleration:Vector2, 
target_position:Vector2, target_velocity:Vector2, target_acceleration:Vector2,
max_thrust:float, brake:float=1)->Vector2:
	
	var relative_position:Vector2 = position - target_position
	var relative_velocity:Vector2 = velocity - target_velocity
	var relative_acceleration:Vector2 = acceleration - target_acceleration
	
	if(relative_position.length()<0.001 || max_thrust<=0):
		return Vector2.ZERO
	
	var brake_dir:Vector2 = Vector2.ZERO if relative_velocity.length()<0.001 else - relative_velocity.normalized()
	var brake_perp:Vector2 = relative_acceleration - relative_acceleration.dot(brake_dir)*brake_dir
	if(max_thrust**2<=brake_perp.length_squared()):
		# thrust won't be able to overcome target acc, just get as close as possible
		if(relative_acceleration.dot(brake_dir)>0):
			return max_thrust*-brake_perp.normalized()
		else:
			return max_thrust*-relative_acceleration.normalized()
	else:
		var brake_acc:float = sqrt(max_thrust**2 - brake_perp.length_squared())+abs(relative_acceleration.dot(brake_dir))
		var brake_thrust:Vector2 = brake_dir*(brake_acc)-relative_acceleration
	
		var brake_time:float = brake * relative_velocity.length()/brake_acc
		var anticipated_position:Vector2 = relative_position + relative_velocity*brake_time
		var pos_corr:Vector2 = relative_position.normalized() if anticipated_position.length()<0.001 else -anticipated_position.normalized()
		var vel_corr:Vector2 = Vector2.ZERO if relative_velocity.length()<0.001 else -relative_velocity.normalized()
		var correction_dir:Vector2 = (pos_corr+vel_corr/2.1).normalized()
		
		var corr_perp:Vector2 = relative_acceleration - relative_acceleration.dot(correction_dir)*correction_dir
		var ret:Dictionary = {}
		if(max_thrust**2<corr_perp.length_squared()):
			# thrust won't be able to overcome target acc, just get as close as possible
			if(relative_acceleration.dot(correction_dir)>=0):
				return max_thrust*-corr_perp.normalized()
			else:
				return max_thrust*-relative_acceleration.normalized()
		else:
			var corr_acc:float = sqrt(max_thrust**2 - corr_perp.length_squared())+abs(relative_acceleration.dot(correction_dir))
			return correction_dir*corr_acc - relative_acceleration

## Finds the thrust needed to get the desired velocity, given the current velocity and acceleration. [param target_acceleration] is a hint for 
## how this target velocity is changing over time.
static func find_thrust_to_velocity(velocity:Vector2, acceleration:Vector2, target_velocity:Vector2, target_acceleration:Vector2, max_thrust:float)->Vector2:
	
	var relative_velocity:Vector2 = velocity - target_velocity
	var relative_acceleration:Vector2 = acceleration - target_acceleration
	
	if(relative_velocity.length()<0.001):
		return Vector2.ZERO
	
	var corr_dir:Vector2 = -relative_velocity.normalized()
	
	var cw:float = relative_acceleration.dot(corr_dir)
	var perp:Vector2 = relative_acceleration - cw*corr_dir
	if(max_thrust**2<perp.length_squared()):
		# thrust won't be able to overcome current acc, just get as close as possible
		if(relative_acceleration.dot(corr_dir)>0):
			return max_thrust*-perp.normalized()
		else:
			return max_thrust*-relative_acceleration.normalized()
	else:
		var acc:float = sqrt(max_thrust**2 - perp.length_squared())+abs(cw)
		return corr_dir*acc-relative_acceleration
	
## Finds a torque to come to rest at a given angle.
static func find_torque_to_angle(rotation:float, angular_velocity:float, target_rotation:float, max_torque:float)->float:
	var brake_time:float = abs(angular_velocity) / max_torque
	var brake_drift:float = angular_velocity*brake_time/2
	if(brake_drift>TAU):
		return -sign(angular_velocity)*max_torque
	var anticipated_position:float = rotation + brake_drift
	return sign(angle_difference(anticipated_position,target_rotation))*max_torque

## Applies a smooth minimum operation to make hitting the max value less abrupt
static func soft_limit_length(v:Vector2, limit:float, softness:float=limit/5)->Vector2:
	var len:float = v.length()
	if(is_equal_approx(len,0)):
		return v
	var newlen:float = log(exp(-v.length()/softness)+exp(-limit/softness))*-softness
	return newlen/len * v

## Finds a direction to shoot a projectile to hit a moving target. The target is assumed to be moving at a constant speed.
## Returns Vector2.ZERO if the target is impossible to hit.
static func aim_shot_linear(position:Vector2, velocity:Vector2, target_position:Vector2, target_velocity:Vector2, proj_speed:float)->Vector2:
	var solution:Dictionary = solve_linear_intercept(proj_speed, target_position-position, target_velocity-velocity)
	if(is_inf(solution.time)):
		return Vector2.ZERO
	else:
		return solution.velocity
	
## Given a target with an initial position and constant velocity, and an agent with initial position of (0,0) and constant speed,
## returns the necessary velocity of the agent to intercept the target, along with the time to the intercept and its location.
static func solve_linear_intercept(speed:float, target_position:Vector2, target_velocity:Vector2)->Dictionary:
	if(target_position.is_zero_approx()):
		# already there
		return {'velocity':Vector2.ZERO,
				'time':0, 
				'intercept':Vector2.ZERO}
	
	var target_dir:Vector2 = target_position.normalized()
	var target_dist:float = target_position.length()
	
	var v:Vector2 = target_velocity
	var vlen:float = v.length()
	if(is_equal_approx(vlen,0)):
		# target is not moving
		return {'velocity':target_dir*speed,
				'time':target_dist/speed,
				'intercept':target_position}
	
	var A:float = -target_position.dot(v)/vlen
	var B:float = target_position.dot(v.orthogonal())/vlen
	if(is_equal_approx(B,0)):
		# target is moving straight at/away from position
		var target_speed:float = target_velocity.dot(target_dir)
		if(target_speed<speed):
			var time:float = target_dist/(speed - target_speed)
			return {'velocity': target_dir * speed,
					'time': time,
					'intercept': target_dir * speed * time}
		else:
			return {'velocity': target_dir * speed,
					'time': INF,
					'intercept': Vector2(INF,INF) * sign(target_dir)}
	
	var a:float = A**2/B**2 + 1
	var b:float = -2*A*vlen/B
	var c:float = vlen**2 - speed**2
	var det:float = b**2 - 4*a*c
	if(det<0):
		# impossible to intercept
		return {'velocity': target_velocity.normalized()*speed,
				'time': INF,
				'intercept': Vector2(INF,INF) * sign(target_velocity)}
	
	var ortho:float = (-b+sqrt(det))/(2*a)
	var T:float = B/ortho
	var alt_ortho:float = (-b-sqrt(det))/(2*a)
	var alt_T:float = B/alt_ortho
	if(alt_T>0 && alt_T<T || T<0 && alt_T>0):
		T=alt_T
		ortho=alt_ortho
	if(T<0):
		# impossible to intercept
		return {'velocity': target_velocity.normalized()*speed,
				'time': INF,
				'intercept': Vector2(INF,INF) * sign(target_velocity)}
	
	var para:float = vlen - ortho*A/B
	var vel:Vector2 = (ortho*v.orthogonal() + para*v)/vlen
	return {'velocity': vel,
			'time': T,
			'intercept': vel * T}
