@tool
class_name BoatAI
extends Node2D

## Damps velocity perpendicular to the ship's heading.
@export var keel_damp:float = 10
## Damps rotation.
@export var keel_angular_damp:float = 10
## Damps velocity parallel to the ship's heading, proportional to the perpendicular keel force.
@export var keel_drag:float = 10

## Max forward thrust.
@export var max_thrust:float = 100

## Highest possible torque (happens when at max speed).
@export var max_torque:float = 100

## Max desired speed. Boat will not voluntarily pass this speed.
@export var max_speed:float = 1000:
	set(to):
		if(max_speed!=to):
			max_speed = to
			if(is_inside_tree() && avoidance_enabled && !Engine.is_editor_hint()):
				NavigationServer2D.agent_set_max_speed(_agent, max_speed)

## Max desired anglular speed. Boat will not voluntarily pass this.
@export var max_angular_speed:float = 1

## Desired (minimum) distance from [member target_position].
@export var desired_distance:float = 500
## Parameter that determines the angle at which the ship approaches the target. 0 means the ship will go straight for the target,
## 1 means the ship will approach such that the target is perpendicular to the ship's heading.
@export_range(0,1) var approach:float = 0.75

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

var linear_velocity:Vector2
var angular_velocity:float

var target_position:Vector2
var target_velocity:Vector2


## The output force to be applied to whatever is obeying this AI
var force:Vector2
## The output torque to be applied to whatever is obeying this AI
var torque:float

## Emitted when [member force] and [member torque] have finished updating
signal forces_updated

signal _avoidance_callback_signal(safe_vel:Vector3)

var _avg_target_velocity:Vector2
var _agent:RID
var _draw_calls:Array[Dictionary]

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

func _physics_process(delta: float) -> void:
	if(Engine.is_editor_hint() && ! debug_draw):
		return
	var next_draw_calls:Array[Dictionary]
	var next_force:Vector2
	var next_torque:float
	
	var keel_dir:Vector2 = Vector2.from_angle(global_rotation).orthogonal()
	var keel_vel:float = linear_velocity.dot(keel_dir)
	var keel_force:Vector2 = keel_dir * -keel_vel * keel_damp
	var para_vel:float = linear_velocity.dot(keel_dir.orthogonal())
	keel_force += keel_dir.orthogonal() * -sign(para_vel)*abs(keel_vel) * keel_drag
	if(debug_draw):
		next_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':keel_force,'color':Color(1,0,0),'global':false})
	next_force += keel_force
	
	var keel_torque:float = -angular_velocity * keel_angular_damp
	next_torque += keel_torque
	
	var target_relpos:Vector2 = target_position - global_position
	var target_dist:float = target_relpos.length()
	
	var weight:float = delta * max_thrust / (desired_distance)
	_avg_target_velocity = (_avg_target_velocity + weight*target_velocity)/(1+weight)
	#_avg_target_velocity = _avg_target_velocity.move_toward(target_velocity,delta*max_thrust)
	
	if(debug_draw):
		next_draw_calls.push_back({'type':'arc','position':target_position,'radius':desired_distance,'color':Color(0,0,1),'global':true})
		next_draw_calls.push_back({'type':'circle','position':target_position,'radius':2,'color':Color(0,0,1),'global':true})
		next_draw_calls.push_back({'type':'line','start':target_position,'end':target_position+_avg_target_velocity,'color':Color(0,0,1),'global':true})
	
	var angular_brake_time:float = abs(angular_velocity)/max_torque
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
		# gives the boat more speed the further it is from the desired distance
		var speed_dfactor:float = sqrt(abs(dist_err)*max_thrust*2)/max_speed
		const angle_factor_base:float = 100
		# makes the boat only thrust forward when facing pretty close to the direction it wants to go
		var speed_afactor:float = angle_factor_base**(current_direction.dot(desired_velocity)-1)
		# makes the boat move just a little bit when facing the wrong direction so it can turn
		var angle_correction_factor:float = 0.1*(-current_direction.dot(desired_velocity) + 1)/2
		var des_speed:float = max_speed * (speed_dfactor * speed_afactor + angle_correction_factor)/1.1
		desired_velocity *= des_speed
	
	desired_velocity += _avg_target_velocity
	desired_velocity.limit_length(max_speed)
	
	if(debug_draw):
		next_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':desired_velocity,'color':Color(0,1,0),'global':false})
	
	if(avoidance_enabled):
		if(debug_draw):
			next_draw_calls.push_back({'type':'circle','position':Vector2.ZERO,'radius':avoidance_radius,'color':Color(0.1,0.8,0.8,0.5),'global':false})
		if(!Engine.is_editor_hint()):
			NavigationServer2D.agent_set_position(_agent, global_position)
			NavigationServer2D.agent_set_velocity(_agent, desired_velocity)
			var safe_vel3:Vector3 = await _avoidance_callback_signal
			desired_velocity = Vector2(safe_vel3.x, safe_vel3.z)
			
			if(debug_draw):
				next_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':desired_velocity,'color':Color(0,1,1),'global':false})
	
	next_torque += sign(angle_difference(angular_brake_pos,desired_velocity.angle())) * abs(para_vel) * max_torque/max_speed
	
	var speed_err:float = linear_velocity.dot(current_direction) - desired_velocity.length()
	var thrust:Vector2 = -tanh(speed_err/4)*max_thrust * current_direction
	if(debug_draw):
		next_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':thrust,'color':Color(1,0,0),'global':false})
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
		var inv:Transform2D = global_transform.affine_inverse()
		for dcall:Dictionary in _draw_calls:
			match dcall.type:
				'line':
					if(dcall.global):
						draw_line(inv * dcall.start, inv * dcall.end, dcall.color)
					else:
						draw_line(inv * (dcall.start+global_position), inv * (dcall.end+global_position), dcall.color)
				'arc':
					if(dcall.global):
						draw_arc(inv * dcall.position, dcall.radius, 0, TAU, 64, dcall.color)
					else:
						draw_arc(inv * (dcall.position+global_position), dcall.radius, 0, TAU, 64, dcall.color)
				'circle':
					if(dcall.global):
						draw_circle(inv * dcall.position, dcall.radius, dcall.color)
					else:
						draw_circle(inv * (dcall.position+global_position), dcall.radius, dcall.color)
