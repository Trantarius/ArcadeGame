extends WeaponAbility

## Angle (in degrees) between simultaneous projectiles (if there are multiple)
@export var spread_per_projectile:float = 15
@export var projectile_lifetime:float = 3

func _on_fire() -> void:
	var bullet_count:int = max(1,floori(projectile_count))
	var spread:float = deg_to_rad(spread_per_projectile * (bullet_count-1))
	
	for n:int in range(floori(projectile_count)):
		var bullet:Projectile = preload("res://abilities/weapon/light_cannon/light_cannon_projectile.tscn").instantiate()
		bullet.global_position = get_parent().get_muzzle_position()
		
		var fire_dir:Vector2 = get_parent().get_muzzle_direction().rotated(spread/2 - n*spread/max(1,bullet_count-1))
		
		bullet.linear_velocity = projectile_speed * fire_dir + get_parent().linear_velocity
		bullet.source = get_parent()
		bullet.damage_amount = damage_amount
		bullet.scale = Vector2.ONE * projectile_size/8
		bullet.lifetime = projectile_lifetime
		get_tree().current_scene.add_child(bullet)
