class_name Spiky
extends Enemy

var target:Player

func _physics_process(_delta: float) -> void:
	
	target = Player.find_nearest_player(position)



func _on_hit_box_damage_dealt(_damage: Damage) -> void:
	queue_free()


func _on_ballistic_ai_pre_update() -> void:
	if(is_instance_valid(target)):
		$BallisticAI.global_transform = global_transform
		$BallisticAI.linear_velocity = $'.'.linear_velocity
		$BallisticAI.angular_velocity = $'.'.angular_velocity
		$BallisticAI.target_position=target.global_position
		$BallisticAI.target_velocity=target.get_average_velocity()
		$BallisticAI.target_acceleration=target.get_average_acceleration()


func _on_ballistic_ai_post_update() -> void:
	if(is_instance_valid(target)):
		$'.'.apply_central_force($BallisticAI.force*self.mass)
		$'.'.apply_torque($BallisticAI.torque)
