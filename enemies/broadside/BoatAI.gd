@tool
class_name BoatAI
extends Node2D

## Damps velocity perpendicular to the ship's heading
@export var keel_damp:float = 4
## Damps rotation
@export var keel_angular_damp:float = 1
## Damps velocity parallel to the ship's heading, proportional to the perpendicular keel force
@export var keel_drag:float = 4

## Max forward thrust.
@export var max_thrust:float = 30

## Max torque when not moving
@export var rest_torque:float = 0.5
## Highest possible torque (happens when at max speed)
@export var max_torque:float = 10

@export var max_speed:float = 500:
	set(to):
		if(max_speed!=to):
			max_speed = to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_max_speed(_agent, max_speed)

@export var max_angular_speed:float = 1

@export var desired_distance:float = 500

@export var ignore_rotation_within_distance:bool = false

@export var debug_draw:bool = false

@export_group("Avoidance","avoidance_")
@export var avoidance_enabled:bool = true:
	set(to):
		if(avoidance_enabled!=to):
			avoidance_enabled = to
			if(is_inside_tree() && !Engine.is_editor_hint()):
				if(avoidance_enabled):
					_start_avoidance()
				else:
					_stop_avoidance()

@export_flags_avoidance var avoidance_layers:int = 1:
	set(to):
		if(avoidance_layers!=to):
			avoidance_layers=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_avoidance_layers(_agent, avoidance_layers)
@export_flags_avoidance var avoidance_mask:int = 1:
	set(to):
		if(avoidance_mask!=to):
			avoidance_mask=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_avoidance_mask(_agent, avoidance_mask)
@export var avoidance_priority:float = 1:
	set(to):
		if(avoidance_priority!=to):
			avoidance_priority=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_avoidance_priority(_agent, avoidance_priority)
@export var avoidance_max_neighbors:int = 10:
	set(to):
		if(avoidance_max_neighbors!=to):
			avoidance_max_neighbors=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_max_neighbors(_agent, avoidance_max_neighbors)
@export var avoidance_neighbor_distance:float = 500:
	set(to):
		if(avoidance_neighbor_distance!=to):
			avoidance_neighbor_distance=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_neighbor_distance(_agent, avoidance_neighbor_distance)
@export var avoidance_radius:float = 10:
	set(to):
		if(avoidance_radius!=to):
			avoidance_radius=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_radius(_agent, avoidance_radius)
@export var avoidance_time_horizon_agents:float = 2:
	set(to):
		if(avoidance_time_horizon_agents!=to):
			avoidance_time_horizon_agents=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_time_horizon_agents(_agent, avoidance_time_horizon_agents)
@export var avoidance_time_horizon_obstacles:float = 2:
	set(to):
		if(avoidance_time_horizon_obstacles!=to):
			avoidance_time_horizon_obstacles=to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_time_horizon_obstacles(_agent, avoidance_time_horizon_obstacles)

var _agent:RID
var _draw_calls:Array[Callable]
var _last_target_side:float = 1

var linear_velocity:Vector2
var angular_velocity:float

var target_position:Vector2
var target_velocity:Vector2

var _avg_target_velocity:Vector2
var _avg_target_position:Vector2

## The output force to be applied to whatever is obeying this AI
var force:Vector2
## The output torque to be applied to whatever is obeying this AI
var torque:float

## Emitted when [member force] and [member torque] have finished updating
signal forces_updated

signal _avoidance_callback_signal(safe_vel:Vector3)

func _avoidance_callback(arg)->void:
	_avoidance_callback_signal.emit(arg)

func _start_avoidance()->void:
	_agent = NavigationServer2D.agent_create()
	NavigationServer2D.agent_set_map(_agent, get_world_2d().navigation_map)
	NavigationServer2D.agent_set_avoidance_enabled(_agent, true)
	NavigationServer2D.agent_set_avoidance_callback(_agent, _avoidance_callback)
	
	NavigationServer2D.agent_set_avoidance_layers(_agent, avoidance_layers)
	NavigationServer2D.agent_set_avoidance_mask(_agent, avoidance_mask)
	NavigationServer2D.agent_set_avoidance_priority(_agent, avoidance_priority)
	NavigationServer2D.agent_set_max_neighbors(_agent, avoidance_max_neighbors)
	NavigationServer2D.agent_set_neighbor_distance(_agent, avoidance_neighbor_distance)
	NavigationServer2D.agent_set_radius(_agent, avoidance_radius)
	NavigationServer2D.agent_set_time_horizon_agents(_agent, avoidance_time_horizon_agents)
	NavigationServer2D.agent_set_time_horizon_obstacles(_agent, avoidance_time_horizon_obstacles)
	NavigationServer2D.agent_set_max_speed(_agent, max_speed)
	
	NavigationServer2D.agent_set_position(_agent, global_position)
	NavigationServer2D.agent_set_velocity(_agent, linear_velocity)

func _stop_avoidance()->void:
	NavigationServer2D.free_rid(_agent)

func _enter_tree() -> void:
	if(avoidance_enabled):
		_start_avoidance()

func _exit_tree() -> void:
	if(avoidance_enabled):
		_stop_avoidance()

func _physics_process(_delta: float) -> void:
	if(Engine.is_editor_hint() && ! debug_draw):
		return
	var next_draw_calls:Array[Callable]
	var next_force:Vector2
	var next_torque:float
	
	var weight:float = _delta/((target_position-global_position).length()/max_speed)
	_avg_target_velocity = (_avg_target_velocity + weight*target_velocity)/(1+weight)
	_avg_target_position = (_avg_target_position + weight*target_position)/(1+weight)
	
	var keel_dir:Vector2 = Vector2.from_angle(global_rotation).orthogonal()
	var keel_vel:float = linear_velocity.dot(keel_dir)
	var keel_force:Vector2 = keel_dir * -keel_vel * keel_damp
	var para_vel:float = linear_velocity.dot(keel_dir.orthogonal())
	keel_force += keel_dir.orthogonal() * -sign(para_vel)*abs(keel_vel) * keel_drag
	if(debug_draw):
		next_draw_calls.push_back(draw_line.bind(Vector2.ZERO, keel_force.rotated(-global_rotation), Color(1,0,0)))
	next_force += keel_force
	
	var keel_torque:float = -angular_velocity * keel_angular_damp
	next_torque += keel_torque
	
	var angular_brake_time:float = abs(angular_velocity)/max_torque
	var angular_brake_drift:float = angular_velocity*angular_brake_time/2
	var angular_brake_pos:float = global_rotation + angular_brake_drift
	
	var tt_a:float = 0.5*max_thrust
	var tt_b:float = linear_velocity.dot((target_position-global_position).normalized())
	var tt_c:float = -(target_position-global_position).length()
	var tt_det:float = tt_b**2 - 4*tt_a*tt_c
	var appx_travel_time:float = (-abs(tt_b) + sqrt(tt_det))/(2*tt_a)
	var appx_avg_speed:float = (target_position-global_position).length()/appx_travel_time
	
	var target_relpos:Vector2 = target_position - global_position
	var solution:Dictionary = Ballistics.solve_linear_intercept(max_speed, target_relpos, _avg_target_velocity)
	var intercept:Vector2 = solution.intercept
	var desired_direction:Vector2 = solution.velocity.normalized()
	var target_dist:float = target_relpos.length()
	
	
	
	if(!is_inf(solution.time)):
		if(debug_draw):
			next_draw_calls.push_back(draw_arc.bind(intercept.rotated(-global_rotation), desired_distance, 0, TAU, 32, Color(0,0,1)))
			next_draw_calls.push_back(draw_circle.bind(intercept.rotated(-global_rotation), 2, Color(0,0,1)))

		target_dist = intercept.length()
		var perp_dir:Vector2 = intercept.normalized().orthogonal()
		perp_dir *= sign(perp_dir.dot(Vector2.from_angle(angular_brake_pos)))
		var perp_angle:float = perp_dir.angle()

		if(target_dist>desired_distance):
			var des_angle:float = asin(desired_distance*0.75/target_dist)
			var curr_angle:float = angle_difference(intercept.angle(), angular_brake_pos)
			
			des_angle = sign(curr_angle)*abs(des_angle)
			desired_direction = Vector2.from_angle(des_angle + intercept.angle())

		elif(ignore_rotation_within_distance):
			desired_direction = Vector2.from_angle(global_rotation)
		else:
			desired_direction = perp_dir
	
	
	var current_direction:Vector2 = Vector2.from_angle(global_rotation)
		
	var dist_err:float = target_dist-desired_distance
	# gives the boat more speed the further it is from the desired distance
	var speed_dfactor:float = sqrt(abs(dist_err)*max_thrust*2)/max_speed
	const min_angle_factor:float = 0.1
	const angle_factor_base:float = 100
	# makes the boat only thrust forward when facing pretty close to the direction it wants to go
	var speed_afactor:float = angle_factor_base**(current_direction.dot(desired_direction)-1)
	# makes the boat move just a little bit when facing the wrong direction so it can turn
	var angle_correction_factor:float = 0.1*(-current_direction.dot(desired_direction) + 1)/2
	var des_speed:float = max_speed * (speed_dfactor * speed_afactor + angle_correction_factor)/1.1
	
	var des_vel:Vector2 = desired_direction * des_speed
	des_vel += _avg_target_velocity
	desired_direction = des_vel.normalized()
	des_speed = min(des_vel.length(),max_speed)
	
	if(debug_draw):
		next_draw_calls.push_back(draw_line.bind(Vector2.ZERO, desired_direction.rotated(-global_rotation) * des_speed, Color(0,1,0)))
	
	if(avoidance_enabled):
		if(debug_draw):
			next_draw_calls.push_back(draw_circle.bind(Vector2.ZERO, avoidance_radius, Color(0.1,0.8,0.8,0.5)))
		if(!Engine.is_editor_hint()):
			NavigationServer2D.agent_set_position(_agent, global_position)
			NavigationServer2D.agent_set_velocity(_agent, desired_direction * des_speed)
			var safe_vel3:Vector3 = await _avoidance_callback_signal
			var safe_vel:Vector2 = Vector2(safe_vel3.x, safe_vel3.z)
			desired_direction = safe_vel.normalized()
			des_speed = safe_vel.length()
			
			if(debug_draw):
				next_draw_calls.push_back(draw_line.bind(Vector2.ZERO, safe_vel.rotated(-global_rotation), Color(0,1,1)))
	
	var desired_angle:float = desired_direction.angle()
	next_torque += sign(angle_difference(angular_brake_pos,desired_angle))*remap(abs(para_vel), 0, max_speed, rest_torque, max_torque)
	
	var speed_err:float = linear_velocity.dot(current_direction) - des_speed
	var thrust:Vector2 = -tanh(speed_err) * current_direction * max_thrust
	if(debug_draw):
		next_draw_calls.push_back(draw_line.bind(Vector2.ZERO, thrust.rotated(-global_rotation), Color(1,0,0)))
	next_force += thrust
	
	next_force += linear_velocity
	next_force = next_force.limit_length(max_speed)
	next_force -= linear_velocity
	
	next_torque += angular_velocity
	next_torque = clamp(next_torque, -max_angular_speed, max_angular_speed)
	next_torque -= angular_velocity
	
	force = next_force
	torque = next_torque
	
	if(debug_draw):
		_draw_calls = next_draw_calls
		queue_redraw()
	
	if(!Engine.is_editor_hint()):
		forces_updated.emit()

func _draw()->void:
	if(debug_draw):
		for dcall:Callable in _draw_calls:
			dcall.call()
