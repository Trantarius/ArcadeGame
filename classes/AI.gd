class_name AI
extends Node2D

## Max self-applied force. Does not affect damping forces.
@export var max_linear_thrust:float = 100

## Max self-applied torque. Does not affect damping forces.
@export var max_angular_thrust:float = 100

## Max desired linear speed. Actor will not voluntarily pass this speed.
@export var max_linear_speed:float = 1000:
	set(to):
		if(max_linear_speed!=to):
			max_linear_speed = to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_max_speed(_agent, max_linear_speed)

## Max desired anglular speed. Actor will not voluntarily pass this speed.
@export var max_angular_speed:float = 1

## Enables drawing debug shapes.
@export var debug_draw:bool = false

@export_group("Avoidance","avoidance_")
@export var avoidance_enabled:bool = true:
	set(to):
		if(avoidance_enabled!=to):
			avoidance_enabled = to
			if(is_inside_tree()):
				if(avoidance_enabled):
					_start_avoidance()
				else:
					_stop_avoidance()

@export_flags_avoidance var avoidance_layers:int = 1:
	set(to):
		if(avoidance_layers!=to):
			avoidance_layers=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_avoidance_layers(_agent, avoidance_layers)

@export_flags_avoidance var avoidance_mask:int = 1:
	set(to):
		if(avoidance_mask!=to):
			avoidance_mask=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_avoidance_mask(_agent, avoidance_mask)

@export var avoidance_priority:float = 1:
	set(to):
		if(avoidance_priority!=to):
			avoidance_priority=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_avoidance_priority(_agent, avoidance_priority)

@export var avoidance_max_neighbors:int = 10:
	set(to):
		if(avoidance_max_neighbors!=to):
			avoidance_max_neighbors=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_max_neighbors(_agent, avoidance_max_neighbors)

@export var avoidance_neighbor_distance:float = 500:
	set(to):
		if(avoidance_neighbor_distance!=to):
			avoidance_neighbor_distance=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_neighbor_distance(_agent, avoidance_neighbor_distance)

@export var avoidance_radius:float = 10:
	set(to):
		if(avoidance_radius!=to):
			avoidance_radius=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_radius(_agent, avoidance_radius)

@export var avoidance_time_horizon_agents:float = 2:
	set(to):
		if(avoidance_time_horizon_agents!=to):
			avoidance_time_horizon_agents=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_time_horizon_agents(_agent, avoidance_time_horizon_agents)

@export var avoidance_time_horizon_obstacles:float = 2:
	set(to):
		if(avoidance_time_horizon_obstacles!=to):
			avoidance_time_horizon_obstacles=to
			if(is_inside_tree() && avoidance_enabled):
				NavigationServer2D.agent_set_time_horizon_obstacles(_agent, avoidance_time_horizon_obstacles)

## Current linear velocity. Parent actor should set this as an input.
var linear_velocity:Vector2
## Current angular velocity. Parent actor should set this as an input.
var angular_velocity:float

## Position the actor should move to.
var target_position:Vector2
## Hints that the [member target_position] will be changing at this rate.
var target_velocity:Vector2
## Hints that the [member target_velocity] will be changing at this rate.
var target_acceleration:Vector2


## The output force to be applied to whatever is obeying this AI.
var force:Vector2
## The output torque to be applied to whatever is obeying this AI.
var torque:float

## Emitted when an update is about to occur
signal pre_update
## Emitted when [member force] and [member torque] have finished updating
signal post_update

var _agent:RID
var _draw_calls:Array[Dictionary]
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
	NavigationServer2D.agent_set_max_speed(_agent, max_linear_speed)
	
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

func _ready() -> void:
	top_level=true

enum{POSITION=0,VELOCITY=1,FORCE=2}
## Virtual function for subclasses to set how output is determined; if an output isn't used, it is calculated from the result.
func _control_level()->int:
	return FORCE

func _physics_process(delta: float) -> void:
	pre_update.emit()
	var oldpos:Vector2=global_position
	var oldrot:float = global_rotation
	var oldvel:Vector2 = linear_velocity
	var oldrvel:float = angular_velocity
	await _update()
	if(_control_level()>=FORCE):
		linear_velocity += force * delta
		angular_velocity += torque * delta
	else:
		force = (linear_velocity-oldvel)/delta
		torque = (angular_velocity-oldrvel)/delta
	if(_control_level()>=VELOCITY):
		global_position += linear_velocity * delta
		global_rotation += angular_velocity * delta
	else:
		linear_velocity = (global_position-oldpos)/delta
		angular_velocity = angle_difference(oldrot,global_rotation)/delta
	post_update.emit()
	if(debug_draw):
		_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':force,'color':Color(0.8,0.8,0.1,0.75),'global':false})
		queue_redraw()

## Virtual function for subclasses to override, to update forces/velocity/position as appropriate.
func _update()->void:
	pass

## Helper for subclasses to apply avoidance. should be called exactly once in _update().
func make_velocity_safe(velocity:Vector2)->Vector2:
	if(debug_draw):
		_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':velocity,'color':Color(0.8,0.1,0.1,0.75),'global':false})
	if(avoidance_enabled):
		if(debug_draw):
			_draw_calls.push_back({'type':'circle','position':Vector2.ZERO,'radius':avoidance_radius,'color':Color(0.1,0.8,0.8,0.5),'global':false})
		NavigationServer2D.agent_set_position(_agent, global_position)
		NavigationServer2D.agent_set_velocity(_agent, velocity)
		var safe_vel3:Vector3 = await _avoidance_callback_signal
		var ret:Vector2 = Vector2(safe_vel3.x,safe_vel3.z)
		if(debug_draw):
			_draw_calls.push_back({'type':'line','start':Vector2.ZERO,'end':ret,'color':Color(0.1,0.8,0.8,0.75),'global':false})
		return ret
	else:
		return velocity

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
						draw_arc(inv * dcall.position, dcall.radius, 0, TAU, 128, dcall.color)
					else:
						draw_arc(inv * (dcall.position+global_position), dcall.radius, 0, TAU, 64, dcall.color)
				'circle':
					if(dcall.global):
						draw_circle(inv * dcall.position, dcall.radius, dcall.color)
					else:
						draw_circle(inv * (dcall.position+global_position), dcall.radius, dcall.color)
		_draw_calls.clear()
