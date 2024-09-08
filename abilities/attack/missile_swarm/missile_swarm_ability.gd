extends CooldownAbility

## The number of missiles fired when the ability is activated.
@export var projectile_count:Stat
## The amount of damage dealt by the explosion each missile causes.
@export var damage:Stat
## The radius of the missile explosion.
@export var explosion_size:Stat
## The maximum deviation from the player's current direction to fire a missile in (in radians).
@export var fire_angle:float = 0.5

func _on_triggered() -> void:
	for n:int in range(projectile_count.get_value()):
		var missile:Node2D = preload("res://abilities/attack/missile_swarm/swarm_missile.tscn").instantiate()
		var theta:float = randf_range(-fire_angle,fire_angle) + get_parent().get_muzzle_direction().angle()
		missile.global_position = get_parent().get_muzzle_position()
		missile.linear_velocity = get_parent().linear_velocity + Vector2.from_angle(theta)*randf_range(80,160)
		missile.global_rotation = theta
		missile.attacker = get_parent()
		missile.source = self
		missile.explosion_damage = damage.get_value()
		missile.explosion_radius = explosion_size.get_value()
	
		get_tree().current_scene.add_child(missile)
