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
	var solution:Dictionary = __solve_linear_intercept(proj_speed, target_position-position, target_velocity-velocity)
	if(is_inf(solution.time)):
		return Vector2.ZERO
	else:
		return solution.velocity
	
## Given a target with an initial position and constant velocity, and an agent with initial position of (0,0) and constant speed,
## returns the necessary velocity of the agent to intercept the target, along with the time to the intercept and its location.
static func __solve_linear_intercept(speed:float, target_position:Vector2, target_velocity:Vector2)->Dictionary:
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

static func cbrt(x:float)->float:
	return sign(x)*pow(abs(x),1.0/3.0)

static func solve_linear_intercept(position:Vector2, speed:float, target_position:Vector2, target_velocity:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position - position
	var v_b:Vector2 = target_velocity
	var F:float = speed
	
	# generated by ballistics_gen.ipynb
	# opcount: 25
	var _0:float = 8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var _1:float = 4.0*((F*F) - (v_b.x*v_b.x) - (v_b.y*v_b.y))
	var _2:float = sqrt((_0*_0) + 16.0*_1*((p_b.x*p_b.x) + (p_b.y*p_b.y)))
	var _3:float = (0.5)/_1
	
	var T1:float = _3*(_0 - _2)
	var T2:float = _3*(_0 + _2)
	var T:float
	if(is_finite(T1) && T1>=0 && (!is_finite(T2)||T1<T2||T2<0)):
		T = T1
	elif(is_finite(T2) && T2>=0 && (!is_finite(T1)||T2<T1||T1<0)):
		T = T2
	else:
		#intercept impossible
		return {'velocity':v_b.limit_length(speed),
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_velocity)}

	var v_a:Vector2
	# generated by ballistics_gen.ipynb
	# opcount: 7
	_0 = 1.0/T
	v_a.x = _0*p_b.x + v_b.x
	v_a.y = _0*p_b.y + v_b.y
	
	return {'velocity':v_a,
			'time':T,
			'intercept':position + (v_a)*T}


static func solve_linear_quadratic_intercept(position:Vector2, speed:float, target_position:Vector2, target_velocity:Vector2, target_acceleration:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position - position
	var v_b:Vector2 = target_velocity
	var a_b:Vector2 = target_acceleration
	var F:float = speed
	
	# generated by ballistics_gen.ipynb
	# opcount: 30
	var _0:float = 4.0*a_b.x
	var _1:float = 4.0*a_b.y
	var c_a:float = -((a_b.x*a_b.x) + (a_b.y*a_b.y))
	var c_b:float = -(_0*v_b.x + _1*v_b.y)
	var c_c:float = 4.0*(F*F) - (_0*p_b.x + _1*p_b.y + 4.0*(v_b.x*v_b.x) + 4.0*(v_b.y*v_b.y))
	var c_d:float = -8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var c_e:float = -4.0*((p_b.x*p_b.x) + (p_b.y*p_b.y))

	# generated by ballistics_gen.ipynb
	# opcount: 97
	_0 = 1.0/c_a
	_1 = (1.0/(c_a*c_a))
	var _2:float = (1.0/3.0)*_0
	var _3:float = _0*c_c
	var _4:float = (c_b*c_b)
	var _5:float = (c_c*c_c*c_c)
	var _6:float = c_a*c_e
	var _7:float = _6*c_c
	var _8:float = c_b*c_d
	var _9:float = _8*c_c
	var _10:float = c_a*(c_d*c_d)
	var _11:float = _4*c_e
	var _12:float = 12.0*_6 - 3.0*_8 + (c_c*c_c)
	var _13:float = cbrt((27.0/2.0)*_10 + (27.0/2.0)*_11 + _5 - 36.0*_7 - 9.0/2.0*_9 + (1.0/2.0)*sqrt(-4.0*(_12*_12*_12) + pow(27.0*_10 + 27.0*_11 + 2.0*_5 - 72.0*_7 - 9.0*_9, 2.0)))
	var _14:float = _12*_2/_13 + _13*_2
	var _15:float = sqrt((1.0/4.0)*_1*_4 + _14 - 2.0/3.0*_3)
	var _16:float = (1.0/4.0)*(-8.0*_0*c_d + 4.0*_1*c_b*c_c - _2*(c_b*c_b*c_b))/_15
	var _17:float = -1.0/2.0*_1*_4 + _14 + (4.0/3.0)*_3
	var _18:float = (1.0/2.0)*sqrt(-_16 - _17)
	var _19:float = (1.0/2.0)*_15
	var _20:float = (1.0/4.0)*_0*c_b
	var _21:float = _19 + _20
	var _22:float = (1.0/2.0)*sqrt(_16 - _17)
	
	print('_3', _3)
	print('_4', _4)
	print('_5', _5)
	print('_6', _6)
	print('_7', _7)
	print('_8', _8)
	print('_9', _9)
	print('_10', _10)
	print('_11', _11)
	print('_12', _12)
	print('_13', _13)
	print('_14', _14)
	print('_15', _15)
	print('_16', _16)
	print('_17', _17)
	print('_18', _18)
	print('_19', _19)
	print('_20', _20)
	print('_21', _21)
	print('_22', _22)
	print()
	
	var T:float = -(_18 + _21)
	var T2:float = _18 - _21
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	T2 = _19 - (_20 + _22)
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	T2 = _19 - _20 + _22
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	
	if(!(is_finite(T)&&T>=0)):
		# intercept impossible
		return {'velocity':target_acceleration.normalized()*speed,
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_acceleration)}

	# generated by ballistics_gen.ipynb
	# opcount: 20
	_0 = (0.5)*T
	_1 = 1.0/T
	_2 = (0.5)*(T*T)
	var v_a_x:float = _0*a_b.x + _1*p_b.x + v_b.x
	var v_a_y:float = _0*a_b.y + _1*p_b.y + v_b.y
	var p_i_x:float = T*v_b.x + _2*a_b.x + p_b.x
	var p_i_y:float = T*v_b.y + _2*a_b.y + p_b.y
	
	return {'velocity':Vector2(v_a_x,v_a_y),
			'time':T,
			'intercept':position + Vector2(p_i_x,p_i_y)}

static func solve_quadratic_linear_intercept(position:Vector2, velocity:Vector2, thrust:float, target_position:Vector2, target_velocity:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position-position
	var v_b:Vector2 = target_velocity-velocity
	var F:float = thrust
	
	# generated by ballistics_gen.ipynb
	# opcount: 118
	var _0:float = (1.0/(F*F))
	var _1:float = -4.0*((v_b.x*v_b.x) + (v_b.y*v_b.y))
	var _2:float = _0*_1
	var _3:float = (0.6666666666666666)*_2
	var _4:float = pow(F, -4.0)
	var _5:float = -8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var _6:float = _4*(_5*_5)
	var _7:float = (_1*_1*_1)/pow(F, 6.0)
	var _8:float = -4.0*((p_b.x*p_b.x) + (p_b.y*p_b.y))
	var _9:float = (0.3333333333333333)*_1*_4*_8 - 0.125*_6 - 0.009259259259259259*_7
	var _10:float = 2.0*cbrt(_9)
	var _11:float = sqrt(-_10 - _3)
	var _12:float = (0.5)*_11
	var _13:float = (1.3333333333333333)*_2
	var _14:float = -_13
	var _15:float = 2.0*_0*_5
	var _16:float = _15/_11
	var _17:float = (0.5)*sqrt(_10 + _14 + _16)
	var _18:float = _0*_8 + (0.08333333333333333)*(_1*_1)*_4
	var _19:float = _18 == 0.0
	var _20:float = -_18
	var _21:float = cbrt(-0.16666666666666666*_1*_4*_8 + (0.0625)*_6 + (0.004629629629629629)*_7 + sqrt((0.037037037037037035)*(_20*_20*_20) + (0.25)*(_9*_9)))
	var _22:float = 2.0*_21
	var _23:float = (0.6666666666666666)*_20/_21
	var _24:float = -_22 + _23
	var _25:float = sqrt(-_24 - _3)
	var _26:float = (0.5)*_25
	var _27:float = _15/_25
	var _28:float = (0.5)*sqrt(_14 + _24 + _27)
	var _29:float = (0.5)*sqrt(_10 - _13 - _16)
	var _30:float = (0.5)*sqrt(-_13 - _22 + _23 - _27)
	
	var T:float = -_12 - _17 if _19 else -_26 - _28
	var T2:float = -_12 + _17 if _19 else -_26 + _28
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	T2 = _12 - _29 if _19 else _26 - _30
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	T2 = _12 + _29 if _19 else _26 + _30
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	
	if(!(is_finite(T)&&T>=0)):
		# intercept impossible
		return {'acceleration':target_velocity.normalized()*thrust,
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_velocity)}

	# generated by ballistics_gen.ipynb
	# opcount: 8
	_0 = T*v_b.x + p_b.x
	_1 = 2.0/(T*T)
	_2 = T*v_b.y + p_b.y
	var a_a_x:float = _0*_1
	var a_a_y:float = _1*_2
	var p_i_x:float = _0
	var p_i_y:float = _2
	
	return {'acceleration':Vector2(a_a_x,a_a_y),
			'time':T,
			'intercept':position + Vector2(p_i_x,p_i_y)}

static func solve_quadratic_intercept(position:Vector2, velocity:Vector2, thrust:float, target_position:Vector2, target_velocity:Vector2, target_acceleration:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position-position
	var v_b:Vector2 = target_velocity-velocity
	var a_b:Vector2 = target_acceleration
	var F:float = thrust
	
	# generated by ballistics_gen.ipynb
	# opcount: 172
	var _0:float = -8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var _1:float = (F*F) - ((a_b.x*a_b.x) + (a_b.y*a_b.y))
	var _2:float = 1.0/_1
	var _3:float = _0*_2
	var _4:float = 4.0*a_b.x
	var _5:float = 4.0*a_b.y
	var _6:float = -(_4*v_b.x + _5*v_b.y)
	var _7:float = (1.0/(_1*_1*_1))
	var _8:float = (_6*_6*_6)*_7
	var _9:float = -(_4*p_b.x + _5*p_b.y + 4.0*(v_b.x*v_b.x) + 4.0*(v_b.y*v_b.y))
	var _10:float = (1.0/(_1*_1))
	var _11:float = _10*_6
	var _12:float = _11*_9
	var _13:float = -_12 + 2.0*_3 + (0.25)*_8
	var _14:float = (_6*_6)
	var _15:float = _2*_9
	var _16:float = (0.6666666666666666)*_15
	var _17:float = _10*_14
	var _18:float = -0.375*_17 + _2*_9
	var _19:float = (_18*_18*_18)
	var _20:float = pow(-0.5*_12 + _3 + (0.125)*_8, 2.0)
	var _21:float = -0.25*_0*_11 + _2*(-4.0*(p_b.x*p_b.x) - 4.0*(p_b.y*p_b.y))
	var _22:float = (0.0625)*_14*_7*_9 + _21 - 0.01171875*pow(_6, 4.0)/pow(_1, 4.0)
	var _23:float = (0.3333333333333333)*_18*_22 - 0.009259259259259259*_19 - 0.125*_20
	var _24:float = 2.0*cbrt(_23)
	var _25:float = sqrt((0.25)*_10*_14 - _16 - _24)
	var _26:float = _13/_25
	var _27:float = (1.3333333333333333)*_15
	var _28:float = (0.5)*_17 - _27
	var _29:float = _24 + _28
	var _30:float = (0.5)*sqrt(_26 + _29)
	var _31:float = (0.5)*_25
	var _32:float = (0.25)*_2*_6
	var _33:float = _31 + _32
	var _34:float = (0.08333333333333333)*_10*(_9*_9) + _21
	var _35:float = _34 == 0.0
	var _36:float = -_34
	var _37:float = cbrt(-0.16666666666666666*_18*_22 + (0.004629629629629629)*_19 + (0.0625)*_20 + sqrt((0.25)*(_23*_23) + (0.037037037037037035)*(_36*_36*_36)))
	var _38:float = 2.0*_37
	var _39:float = (0.6666666666666666)*_36/_37
	var _40:float = _38 - _39
	var _41:float = sqrt(-_16 + (0.25)*_17 + _40)
	var _42:float = _13/_41
	var _43:float = (0.5)*sqrt(_28 - _38 + _39 + _42)
	var _44:float = (0.5)*_41
	var _45:float = _32 + _44
	var _46:float = (0.5)*sqrt(-_26 + _29)
	var _47:float = (0.5)*sqrt((0.5)*_10*_14 - _27 - _40 - _42)
	var _48:float = -_32
	
	var T:float = -_30 - _33 if _35 else -_43 - _45
	var T2:float = _30 - _33 if _35 else _43 - _45
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	T2 = _31 - _32 - _46 if _35 else -_32 + _44 - _47
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	T2 = _31 + _46 + _48 if _35 else _44 + _47 + _48
	if(is_finite(T2) && T2>=0 && (!is_finite(T)||T<0||T2<T)):
		T=T2
	
	if(!(is_finite(T)&&T>=0)):
		# intercept impossible
		return {'acceleration':target_acceleration.limit_length(thrust),
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_acceleration)}

	# generated by ballistics_gen.ipynb
	# opcount: 20
	_0 = (T*T)
	_1 = 2.0/_0
	_2 = 2.0/T
	_3 = (0.5)*_0
	var a_a_x:float = _1*p_b.x + _2*v_b.x + a_b.x
	var a_a_y:float = _1*p_b.y + _2*v_b.y + a_b.y
	var p_i_x:float = T*v_b.x + _3*a_b.x + p_b.x
	var p_i_y:float = T*v_b.y + _3*a_b.y + p_b.y
	
	return {'acceleration':Vector2(a_a_x,a_a_y),
			'time':T,
			'intercept':position + Vector2(p_i_x,p_i_y)}
