extends Enemy

func fire()->void:
	var proj:Projectile = preload("res://enemies/broadside/cannon_projectile.tscn").instantiate()
	proj.top_level = true
	proj.global_transform = $Muzzle.global_transform
	proj.linear_velocity = 300*Vector2.from_angle($Muzzle.global_rotation) + get_average_velocity()
	proj.source = self
	get_tree().current_scene.add_child(proj)
