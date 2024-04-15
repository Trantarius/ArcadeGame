class_name Spiky
extends Enemy


func _physics_process(_delta: float) -> void:
	
	var target:Player = find_nearest_player()
	if(target==null):
		linear_target = position
		angular_target = 0
	else:
		linear_target = target.position
		angular_target = sin(constant_force.angle_to(linear_velocity)) * max_angular_thrust

