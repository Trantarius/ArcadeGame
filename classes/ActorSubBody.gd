class_name ActorSubBody
extends RigidBody2D

@export var max_correction_force:float = 1000
@export var max_correction_torque:float = 1000
@export var breakable:bool = false
@export var parent_actor:RigidBody2D
@export var target_marker:Node2D

var correction_impulse:Vector2
var correction_torque:float
var is_broken:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_integrator = true
	global_transform = target_marker.global_transform if is_instance_valid(target_marker) else parent_actor.global_transform
	parent_actor.add_collision_exception_with(self)
	add_collision_exception_with(parent_actor)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if(is_broken):
		return
	var parent:PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(parent_actor.get_rid())
	
	var target_transform:Transform2D = target_marker.global_transform if is_instance_valid(target_marker) else parent_actor.global_transform
	
	var collision:KinematicCollision2D = move_and_collide(target_transform.origin-state.transform.origin)
	if(is_instance_valid(collision)):
		state.transform.origin += collision.get_travel()
	else:
		state.transform.origin = target_transform.origin
	
	var target_linear_velocity:Vector2 = parent.get_velocity_at_local_position(target_transform.origin - parent.transform.origin)
	var target_angular_velocity:float = parent.angular_velocity
	var linear_error:Vector2 = target_transform.origin - state.transform.origin
	var angular_error:float = angle_difference(state.transform.get_rotation(), target_transform.get_rotation())
	
	var next_correction_impulse:Vector2 = linear_error/state.step + (target_linear_velocity - state.linear_velocity)
	correction_impulse = (next_correction_impulse/20)
	if(breakable && correction_impulse.length()>max_correction_force):
		is_broken=true
		return
	correction_impulse = correction_impulse.limit_length(max_correction_force)
	
	var next_correction_torque:float = angular_error/state.step  + (target_angular_velocity-state.angular_velocity)
	correction_torque = next_correction_torque*5
	if(breakable && abs(correction_torque)>max_correction_torque):
		is_broken=true
		return
	correction_torque = clamp(correction_torque, -max_correction_torque, max_correction_torque)
	
	state.apply_impulse(correction_impulse)
	state.apply_torque_impulse(correction_torque)
	parent.apply_impulse(-correction_impulse, target_transform.origin - parent.transform.origin)
	parent.apply_torque_impulse(-correction_torque)
