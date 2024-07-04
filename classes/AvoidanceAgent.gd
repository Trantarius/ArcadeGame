## Nominally similar to [NavigationAgent2D], but doesn't utilize pathfinding at all.
## Also has some additional debug utility, and is more self-contained.
@tool
class_name AvoidanceAgent
extends Node2D

@export var dv_limit:float = -1

@export var max_speed:float = 100:
	set(to):
		max_speed=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_max_speed(_agent, max_speed)

@export_flags_avoidance var layers:int = 1:
	set(to):
		layers=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_avoidance_layers(_agent, layers)

@export_flags_avoidance var mask:int = 1:
	set(to):
		mask=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_avoidance_mask(_agent, mask)

@export var priority:float = 1:
	set(to):
		priority=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_avoidance_priority(_agent, priority)

@export var max_neighbors:int = 10:
	set(to):
		max_neighbors=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_max_neighbors(_agent, max_neighbors)

@export var neighbor_distance:float = 500:
	set(to):
		neighbor_distance=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_neighbor_distance(_agent, neighbor_distance)

@export var radius:float = 10:
	set(to):
		radius=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_radius(_agent, radius)
		if(Engine.is_editor_hint()):
			queue_redraw()

@export var time_horizon_agents:float = 2:
	set(to):
		time_horizon_agents=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_time_horizon_agents(_agent, time_horizon_agents)

@export var time_horizon_obstacles:float = 2:
	set(to):
		time_horizon_obstacles=to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_time_horizon_obstacles(_agent, time_horizon_obstacles)

var velocity:Vector2:
	set(to):
		velocity = to
		if(is_inside_tree() && !Engine.is_editor_hint()):
			NavigationServer2D.agent_set_velocity(_agent, velocity)

# used for debug drawing
var _pre_update_velocity:Vector2
var _post_update_velocity:Vector2

## Emitted when an update is about to occur ([member AvoidanceAgent.velocity] should be set now).
signal pre_update
## Emitted after the update is done ([member AvoidanceAgent.velocity] should be retrieved now).
signal post_update

var _agent:RID
signal _avoidance_callback_signal(safe_vel:Vector3)

func _avoidance_callback(arg)->void:
	_avoidance_callback_signal.emit(arg)

func _enter_tree()->void:
	_agent = NavigationServer2D.agent_create()
	NavigationServer2D.agent_set_map(_agent, get_world_2d().navigation_map)
	NavigationServer2D.agent_set_avoidance_enabled(_agent, true)
	NavigationServer2D.agent_set_avoidance_callback(_agent, _avoidance_callback)
	
	NavigationServer2D.agent_set_avoidance_layers(_agent, layers)
	NavigationServer2D.agent_set_avoidance_mask(_agent, mask)
	NavigationServer2D.agent_set_avoidance_priority(_agent, priority)
	NavigationServer2D.agent_set_max_neighbors(_agent, max_neighbors)
	NavigationServer2D.agent_set_neighbor_distance(_agent, neighbor_distance)
	NavigationServer2D.agent_set_radius(_agent, radius)
	NavigationServer2D.agent_set_time_horizon_agents(_agent, time_horizon_agents)
	NavigationServer2D.agent_set_time_horizon_obstacles(_agent, time_horizon_obstacles)
	NavigationServer2D.agent_set_max_speed(_agent, max_speed)
	
	NavigationServer2D.agent_set_position(_agent, global_position)
	NavigationServer2D.agent_set_velocity_forced(_agent, velocity)

func _exit_tree() -> void:
	NavigationServer2D.free_rid(_agent)

func set_velocity_forced(vel:Vector2)->void:
	velocity = vel
	NavigationServer2D.agent_set_velocity_forced(_agent, velocity)

func _physics_process(delta: float) -> void:
	if(!Engine.is_editor_hint()):
		pre_update.emit()
		
		_pre_update_velocity = velocity
		NavigationServer2D.agent_set_position(_agent, global_position)
		NavigationServer2D.agent_set_velocity(_agent, velocity)
		var safe_vel3:Vector3 = await _avoidance_callback_signal
		if(dv_limit>0):
			velocity = _pre_update_velocity + (Vector2(safe_vel3.x,safe_vel3.z)-_pre_update_velocity).limit_length(dv_limit*delta)
		else:
			velocity = Vector2(safe_vel3.x,safe_vel3.z)
		_post_update_velocity = velocity
		
		post_update.emit()
	
		if(get_tree().debug_navigation_hint):
			queue_redraw()

func _draw()->void:
	if(get_tree().debug_navigation_hint || Engine.is_editor_hint()):
		draw_circle(Vector2.ZERO, radius, ProjectSettings.get_setting('debug/shapes/avoidance/agents_radius_color'))
	if(get_tree().debug_navigation_hint && !Engine.is_editor_hint()):
		var inv:Transform2D = global_transform.affine_inverse()
		draw_line(Vector2.ZERO, inv*(global_position+_pre_update_velocity), Color(0.8,0.2,0.2,0.5))
		draw_line(Vector2.ZERO, inv*(global_position+_post_update_velocity), Color(0.2,0.8,0.8,0.5))
