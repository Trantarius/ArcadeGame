class_name Spiky
extends Enemy


func _physics_process(_delta: float) -> void:
	
	var target:Player = find_nearest_player()
	if(target==null):
		linear_control_mode=ControlMode.THRUST
		linear_target = Vector2.ZERO
		angular_target = 0
	else:
		linear_control_mode=ControlMode.POSITION
		linear_target = target.position
		angular_target = sin(constant_force.angle_to(linear_velocity)) * max_angular_thrust

