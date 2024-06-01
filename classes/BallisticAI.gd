class_name BallisticAI
extends AI

## Controls how much thrust will be reversed to try to come to rest at the target position.
@export var brake_strength:float = 1

func _physics_process(_delta: float) -> void:
	var next_force:Vector2
	var next_torque:float
	var next_draw_calls:Array[Dictionary]
	
	var relative_position:Vector2 = global_position - target_position
	var relative_velocity:Vector2 = linear_velocity - target_velocity
	
	var brake_time:float = relative_velocity.length()/max_linear_thrust
	var brake_pos:Vector2 = relative_position + relative_velocity * brake_time/2
	var desired_speed:float = sqrt(2*relative_position.length()*max_linear_thrust)
	var desired_velocity:Vector2 = desired_speed * -brake_pos.normalized()
	
				
	
	next_force = next_force.limit_length(max_linear_thrust)
	next_force += linear_velocity
	next_force = next_force.limit_length(max_linear_speed)
	next_force -= linear_velocity
	
	next_torque = clamp(next_torque, -max_angular_thrust, max_angular_thrust)
	next_torque += angular_velocity
	next_torque = clamp(next_torque,-max_angular_speed,max_angular_speed)
	next_torque -= angular_velocity
	
	force = next_force
	torque = next_torque
	if(debug_draw):
		_draw_calls=next_draw_calls
		queue_redraw()
	
	forces_updated.emit()
