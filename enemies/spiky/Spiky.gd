class_name Spiky
extends Enemy

@export var max_thrust:float
@export var max_torque:float
@export var max_speed:float

func _physics_process(_delta: float) -> void:
	
	var target:Player = Player.find_nearest_player(position)
	if(is_instance_valid(target)):
		var thrust:Vector2 = Ballistics.find_thrust_to_position(global_position, self.linear_velocity, Vector2.ZERO, 
			target.global_position, target.linear_velocity, Vector2.ZERO, max_thrust, 0)
		$'.'.apply_force(thrust)
		$'.'.apply_torque(sin(thrust.angle_to($'.'.linear_velocity)) * max_torque)
	
	$'.'.linear_velocity = $'.'.linear_velocity.limit_length(max_speed)



func _on_hit_box_damage_dealt(_damage: Damage) -> void:
	queue_free()
