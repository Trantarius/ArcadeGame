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
	var solution:Dictionary = solve_linear_intercept(position, proj_speed, target_position, target_velocity-velocity)
	if(is_inf(solution.time)):
		return Vector2.ZERO
	else:
		return solution.velocity

## Iterates a simple rotation simulation to come to rest at a desired rotation. 
## Returns a dict of form {'rotation':float, 'angular_velocity':float, 'torque':float}.
static func solve_torque(rotation:float, angular_velocity:float, max_torque:float, target_rotation:float, step:float)->Dictionary:
	# xf = xi + vi*t - 1/2 a*t**2
	# t = vi/a
	# xf = xi + vi**2 / a - 1/2 vi**2 / a
	# xf-xi = vi**2 / 2 a
	# sqrt( 2 a (xf-xi) ) = vi
	
	var t_diff:float = angle_difference(rotation+angular_velocity*step/2, target_rotation)
	var alt_diff:float = t_diff+TAU if t_diff<0 else t_diff-TAU
	
	var des_vel:float = sqrt(2*max_torque*abs(t_diff))*sign(t_diff)
	var alt_vel:float = sqrt(2*max_torque*abs(alt_diff))*sign(alt_diff)
	if(abs(angular_velocity-alt_vel)<abs(angular_velocity-des_vel)):
		des_vel = alt_vel
	
	var v_corr:float = des_vel - angular_velocity
	var torque:float = clamp(v_corr/step,-max_torque,max_torque)
	
	var imm_vel:float = angle_difference(rotation,target_rotation)/step
	if(abs(imm_vel) < max_torque*step && abs(imm_vel-angular_velocity)<max_torque*step):
		torque = (imm_vel-angular_velocity)/step
	
	var next_vel:float = angular_velocity + step*torque
	var next_rot:float = rotation + next_vel*step
	
	return {&'rotation':angle_difference(0,next_rot), &'angular_velocity':next_vel, &'torque':torque}

## Finds an acceleration vector for a path to reach a point moving at a velocity, and stay there. This acceleration is not constant.
static func solve_rendezvous(position:Vector2, velocity:Vector2, thrust:float, target_position:Vector2, target_velocity:Vector2)->Vector2:
	
	var tpos:Vector2 = target_position - position
	var vel:Vector2 = velocity - target_velocity
	var brake_time:float = vel.length()/thrust
	var brake_pos:Vector2 = vel*brake_time/2
	var corr:Vector2 = tpos-brake_pos
	if(corr.is_zero_approx()):
		if(vel.is_zero_approx()):
			return Vector2.ZERO
		return -vel.normalized()*thrust
	return corr.normalized()*thrust


## Solves the function a*T**4 + b*T**3 + c*T**2 + d*T + e == 0 for T.
## Selects the smallest positive solution. 
## If no solutions are real and positive, returns NAN.
static func solve_quart(a:float, b:float, c:float, d:float, e:float)->float:
	# generated by ballistics_gen.ipynb
	# opcount: 268
	var _0:float = 1.0/a
	var _1:float = _0*c
	var _2:float = (1.0/(a*a))
	var _3:float = (b*b)
	var _4:float = _2*_3
	var _5:float = _1 - 3.0/8.0*_4
	var _6:float = (_5*_5*_5)
	var _7:float = _0*d
	var _8:float = _2*b
	var _9:float = _8*c
	var _10:float = (1.0/(a*a*a))
	var _11:float = _10*(b*b*b)
	var _12:float = pow((1.0/8.0)*_11 + _7 - 1.0/2.0*_9, 2.0)
	var _13:float = _0*e
	var _14:float = _8*d
	var _15:float = _13 - 1.0/4.0*_14
	var _16:float = (1.0/16.0)*_10*_3*c + _15 - 3.0/256.0*pow(b, 4.0)/pow(a, 4.0)
	var _17:float = -1.0/8.0*_12 + (1.0/3.0)*_16*_5 - 1.0/108.0*_6
	var _18:float = (1.0/3.0)*atan2(0.0, _17)
	var _19:float = sin(_18)
	var _20:float = (_17*_17)
	var _21:float = 2.0*pow(_20, 1.0/6.0)
	var _22:float = _19*_21
	var _23:float = (2.0/3.0)*_1
	var _24:float = _21*cos(_18)
	var _25:float = (1.0/4.0)*_2*_3 - (_23 + _24)
	var _26:float = (1.0/2.0)*atan2(-_22, _25)
	var _27:float = sin(_26)
	var _28:float = pow(4.0*(_19*_19)*cbrt(_20) + (_25*_25), 1.0/4.0)
	var _29:float = 1.0/_28
	var _30:float = (1.0/4.0)*_11 + 2.0*_7 - _9
	var _31:float = _29*_30
	var _32:float = _22 - _27*_31
	var _33:float = cos(_26)
	var _34:float = -4.0/3.0*_1 + (1.0/2.0)*_4
	var _35:float = _24 + _34
	var _36:float = _31*_33 + _35
	var _37:float = (1.0/2.0)*atan2(_32, _36)
	var _38:float = (1.0/2.0)*pow((_32*_32) + (_36*_36), 1.0/4.0)
	var _39:float = _38*cos(_37)
	var _40:float = (1.0/2.0)*_28
	var _41:float = _33*_40
	var _42:float = (1.0/4.0)*_0*b
	var _43:float = _41 + _42
	var _44:float = _2*(c*c)
	var _45:float = _15 + (1.0/12.0)*_44
	var _46:float = _45 == 0.0
	var _47:float = (1.0/4.0)*_20 - 1.0/27.0*(_45*_45*_45)
	var _48:float = (_47*_47)
	var _49:float = pow(_48, 1.0/4.0)
	var _50:float = (1.0/2.0)*atan2(0.0, _47)
	var _51:float = sin(_50)
	var _52:float = (1.0/16.0)*_12 - 1.0/6.0*_16*_5 + _49*cos(_50) + (1.0/216.0)*_6
	var _53:float = (1.0/3.0)*atan2(_49*_51, _52)
	var _54:float = sin(_53)
	var _55:float = pow(sqrt(_48)*(_51*_51) + (_52*_52), 1.0/6.0)
	var _56:float = 2.0*_55
	var _57:float = _54*_56
	var _58:float = 1.0/_55
	var _59:float = (2.0/3.0)*_13 - 1.0/6.0*_14 + (1.0/18.0)*_44
	var _60:float = _58*_59
	var _61:float = -_54*_60 + _57
	var _62:float = cos(_53)
	var _63:float = _56*_62
	var _64:float = -_23 + (1.0/4.0)*_4 + _60*_62 + _63
	var _65:float = (1.0/2.0)*atan2(_61, _64)
	var _66:float = sin(_65)
	var _67:float = pow((_61*_61) + (_64*_64), 1.0/4.0)
	var _68:float = 1.0/_67
	var _69:float = _30*_68
	var _70:float = -_58*_59
	var _71:float = _54*_70 + _57
	var _72:float = -(_66*_69 + _71)
	var _73:float = cos(_65)
	var _74:float = _34 + _62*_70 - _63
	var _75:float = _69*_73 + _74
	var _76:float = (1.0/2.0)*atan2(_72, _75)
	var _77:float = (1.0/2.0)*pow((_72*_72) + (_75*_75), 1.0/4.0)
	var _78:float = _77*cos(_76)
	var _79:float = (1.0/2.0)*_67
	var _80:float = _73*_79
	var _81:float = _42 + _80
	var _82:float = _27*_40
	var _83:float = _38*sin(_37)
	var _84:float = _66*_79
	var _85:float = _77*sin(_76)
	var _86:float = -_82
	var _87:float = -_30
	var _88:float = _29*_87
	var _89:float = _22 - _27*_88
	var _90:float = _33*_88 + _35
	var _91:float = (1.0/2.0)*atan2(_89, _90)
	var _92:float = (1.0/2.0)*pow((_89*_89) + (_90*_90), 1.0/4.0)
	var _93:float = _92*cos(_91)
	var _94:float = _68*_87
	var _95:float = -(_66*_94 + _71)
	var _96:float = _73*_94 + _74
	var _97:float = (1.0/2.0)*atan2(_95, _96)
	var _98:float = (1.0/2.0)*pow((_95*_95) + (_96*_96), 1.0/4.0)
	var _99:float = _98*cos(_97)
	var _100:float = _92*sin(_91)
	var _101:float = _98*sin(_97)
	var _102:float = -_42

	var T:float = NAN

	var T_r:float = -_39 - _43 if _46 else -_78 - _81
	var T_i:float = -_82 - _83 if _46 else -_84 - _85
	if(is_finite(T_r) && T_r>=0 && is_zero_approx(T_i) && (!is_finite(T) || T_r<T)):
		T=T_r
	
	T_r = _39 - _43 if _46 else _78 - _81
	T_i = _83 + _86 if _46 else -_84 + _85
	if(is_finite(T_r) && T_r>=0 && is_zero_approx(T_i) && (!is_finite(T) || T_r<T)):
		T=T_r
		
	T_r = _41 - _42 - _93 if _46 else -_42 + _80 - _99
	T_i = -_100 - _86 if _46 else -_101 + _84
	if(is_finite(T_r) && T_r>=0 && is_zero_approx(T_i) && (!is_finite(T) || T_r<T)):
		T=T_r
		
	T_r = _102 + _41 + _93 if _46 else _102 + _80 + _99
	T_i = _100 + _82 if _46 else _101 + _84
	if(is_finite(T_r) && T_r>=0 && is_zero_approx(T_i) && (!is_finite(T) || T_r<T)):
		T=T_r
	
	return T


static func cbrt(x:float)->float:
	return sign(x)*pow(abs(x),1.0/3.0)

## Finds the velocity of a linearly moving point to intersect a linearly moving target.
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

## Finds the velocity of a linearly moving point to intersect a quadratically moving target.
static func solve_linear_quadratic_intercept(position:Vector2, speed:float, target_position:Vector2, target_velocity:Vector2, target_acceleration:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position - position
	var v_b:Vector2 = target_velocity
	var a_b:Vector2 = target_acceleration
	var F:float = speed
	
	# generated by ballistics_gen.ipynb
	# opcount: 30
	var _0:float = 4.0*a_b.x
	var _1:float = 4.0*a_b.y
	var a:float = -((a_b.x*a_b.x) + (a_b.y*a_b.y))
	var b:float = -(_0*v_b.x + _1*v_b.y)
	var c:float = 4.0*(F*F) - (_0*p_b.x + _1*p_b.y + 4.0*(v_b.x*v_b.x) + 4.0*(v_b.y*v_b.y))
	var d:float = -8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var e:float = -4.0*((p_b.x*p_b.x) + (p_b.y*p_b.y))

	var T:float = solve_quart(a,b,c,d,e)
	if(is_nan(T)):
		# intercept impossible
		return {'velocity':target_acceleration.normalized()*speed,
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_acceleration)}

	# generated by ballistics_gen.ipynb
	# opcount: 20
	_0 = (1.0/2.0)*T
	_1 = 1.0/T
	var _2:float = (1.0/2.0)*(T*T)
	var v_a_x:float = _0*a_b.x + _1*p_b.x + v_b.x
	var v_a_y:float = _0*a_b.y + _1*p_b.y + v_b.y
	var p_i_x:float = T*v_b.x + _2*a_b.x + p_b.x
	var p_i_y:float = T*v_b.y + _2*a_b.y + p_b.y
	
	var ret:Dictionary = {'velocity':Vector2(v_a_x,v_a_y),
			'time':T,
			'intercept':position + Vector2(p_i_x,p_i_y)}
	return ret

## Finds the acceleration of a quadratically moving point to intersect a linearly moving target.
static func solve_quadratic_linear_intercept(position:Vector2, velocity:Vector2, thrust:float, target_position:Vector2, target_velocity:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position-position
	var v_b:Vector2 = target_velocity-velocity
	var F:float = thrust
	
	# generated by ballistics_gen.ipynb
	# opcount: 16
	var a:float = (F*F)
	var b:float = 0.0
	var c:float = -4.0*((v_b.x*v_b.x) + (v_b.y*v_b.y))
	var d:float = -8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var e:float = -4.0*((p_b.x*p_b.x) + (p_b.y*p_b.y))

	var T:float = solve_quart(a,b,c,d,e)
	if(is_nan(T)):
		# intercept impossible
		return {'acceleration':target_velocity.normalized()*thrust,
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_velocity)}

	# generated by ballistics_gen.ipynb
	# opcount: 8
	var _0:float = T*v_b.x + p_b.x
	var _1:float = 2.0/(T*T)
	var _2:float = T*v_b.y + p_b.y
	var a_a_x:float = _0*_1
	var a_a_y:float = _1*_2
	var p_i_x:float = _0
	var p_i_y:float = _2

	
	return {'acceleration':Vector2(a_a_x,a_a_y),
			'time':T,
			'intercept':position + Vector2(p_i_x,p_i_y) + velocity*T}

## Finds the acceleration of a quadratically moving point to intersect a quadratically moving target.
static func solve_quadratic_intercept(position:Vector2, velocity:Vector2, thrust:float, target_position:Vector2, target_velocity:Vector2, target_acceleration:Vector2)->Dictionary:
	
	var p_b:Vector2 = target_position-position
	var v_b:Vector2 = target_velocity-velocity
	var a_b:Vector2 = target_acceleration
	var F:float = thrust
	
	# generated by ballistics_gen.ipynb
	# opcount: 27
	var _0:float = 4.0*a_b.x
	var _1:float = 4.0*a_b.y
	var a:float = (F*F) - ((a_b.x*a_b.x) + (a_b.y*a_b.y))
	var b:float = -(_0*v_b.x + _1*v_b.y)
	var c:float = -(_0*p_b.x + _1*p_b.y + 4.0*(v_b.x*v_b.x) + 4.0*(v_b.y*v_b.y))
	var d:float = -8.0*(p_b.x*v_b.x + p_b.y*v_b.y)
	var e:float = -4.0*((p_b.x*p_b.x) + (p_b.y*p_b.y))

	var T:float = solve_quart(a,b,c,d,e)
	
	if(is_nan(T)):
		# intercept impossible
		return {'acceleration':target_acceleration.limit_length(thrust),
				'time':INF,
				'intercept':Vector2(INF,INF)*sign(target_acceleration)}

	# generated by ballistics_gen.ipynb
	# opcount: 20
	_0 = (T*T)
	_1 = 2.0/_0
	var _2:float = 2.0/T
	var _3:float = (1.0/2.0)*_0
	var a_a_x:float = _1*p_b.x + _2*v_b.x + a_b.x
	var a_a_y:float = _1*p_b.y + _2*v_b.y + a_b.y
	var p_i_x:float = T*v_b.x + _3*a_b.x + p_b.x
	var p_i_y:float = T*v_b.y + _3*a_b.y + p_b.y
	
	
	return {'acceleration':Vector2(a_a_x,a_a_y),
			'time':T,
			'intercept':position + Vector2(p_i_x,p_i_y) + velocity*T}
