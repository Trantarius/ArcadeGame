class_name BoatAI
extends AI

## Damps velocity perpendicular to the ship's heading.
@export var keel_damp:float = 10
## Damps rotation.
@export var keel_angular_damp:float = 10
## Damps velocity parallel to the ship's heading, proportional to the perpendicular keel force.
@export var keel_drag:float = 10

## Desired (minimum) distance from [member target_position].
@export var desired_distance:float = 500
## Parameter that determines the angle at which the ship approaches the target. 0 means the ship will go straight for the target,
## 1 means the ship will approach such that the target is perpendicular to the ship's heading.
@export_range(0,1) var approach:float = 0.75

var _avg_target_velocity:Vector2

func _update() -> void:
	force = Vector2.ZERO
	torque = 0
	
	var keel_dir:Vector2 = Vector2.from_angle(global_rotation).orthogonal()
	var keel_vel:float = linear_velocity.dot(keel_dir)
	var keel_force:Vector2 = keel_dir * -keel_vel * keel_damp
	var para_vel:float = linear_velocity.dot(keel_dir.orthogonal())
	keel_force += keel_dir.orthogonal() * -sign(para_vel)*abs(keel_vel) * keel_drag
	if(debug_draw):
		_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':keel_force,'color':Color(1,0,0),'global':false})
	force += keel_force
	
	var keel_torque:float = -angular_velocity * keel_angular_damp
	torque += keel_torque
	
	var target_relpos:Vector2 = target_position - global_position
	var target_dist:float = target_relpos.length()
	
	if(debug_draw):
		_draw_calls.push_back({'type':'arc','position':target_position,'radius':desired_distance,'color':Color(0,0,1),'global':true})
		_draw_calls.push_back({'type':'circle','position':target_position,'radius':2,'color':Color(0,0,1),'global':true})
		_draw_calls.push_back({'type':'line','start':target_position,'end':target_position+_avg_target_velocity,'color':Color(0,0,1),'global':true})
	
	var angular_brake_time:float = abs(angular_velocity)/max_angular_thrust
	var angular_brake_drift:float = angular_velocity * angular_brake_time/2
	var angular_brake_pos:float = global_rotation + angular_brake_drift
	
	var current_direction:Vector2 = Vector2.from_angle(global_rotation)
	var desired_velocity:Vector2
	if(target_dist>desired_distance):
		var app_angle:float = asin(desired_distance*approach/target_dist)
		var curr_angle:float = angle_difference(target_relpos.angle(), angular_brake_pos)
		
		app_angle = sign(curr_angle)*abs(app_angle)
		desired_velocity = Vector2.from_angle(app_angle + target_relpos.angle())
		
		var dist_err:float = max(target_dist-desired_distance, 0)
		var des_speed:float = sqrt(abs(dist_err)*max_linear_thrust*2)
		desired_velocity *= des_speed
	
	#desired_velocity += target_velocity
	desired_velocity = desired_velocity.limit_length(max_linear_speed)
	desired_velocity = await make_velocity_safe(desired_velocity)
	
	torque += sign(angle_difference(angular_brake_pos,desired_velocity.angle())) * (abs(para_vel)+5) * max_angular_thrust/max_linear_speed
	
	var speed_err:float = linear_velocity.dot(current_direction) - desired_velocity.dot(current_direction)
	var thrust:Vector2 = -tanh(speed_err/4)*max_linear_thrust * current_direction
	if(debug_draw):
		_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':thrust,'color':Color(0.8,0.8,0),'global':false})
	force += thrust
	
	force += linear_velocity
	force = force.limit_length(max_linear_speed)
	force -= linear_velocity
		
	torque += angular_velocity
	torque = clamp(torque, -max_angular_speed, max_angular_speed)
	torque -= angular_velocity
	
