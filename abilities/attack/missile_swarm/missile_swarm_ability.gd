extends CooldownAbility

@export var missile_count:int = 4
@export var fire_angle:float = 0.5

func _on_triggered() -> void:
	for n:int in range(missile_count):
		var missile:Node2D = preload("res://abilities/attack/missile_swarm/swarm_missile.tscn").instantiate()
		var theta:float = randf_range(-fire_angle,fire_angle) + get_parent().get_muzzle_direction().angle()
		missile.global_position = get_parent().get_muzzle_position()
		missile.linear_velocity = get_parent().linear_velocity + Vector2.from_angle(theta)*randf_range(80,160)
		missile.global_rotation = theta
		missile.source = get_parent()
	
		get_tree().current_scene.add_child(missile)
