extends WeaponAbility

func _on_fire() -> void:
	
	var muzzle_pos:Vector2 = get_parent().get_muzzle_position()
	var muzzle_dir:Vector2 = get_parent().get_muzzle_direction()
	
	$ArcDetector.max_angle = deg_to_rad(projectile_size)
	$ArcDetector.max_range = projectile_speed
	$ArcDetector.update_detected()
	$ArcDetector.global_position = muzzle_pos
	
	if($ArcDetector.detected.is_empty()):
	
		for n:int in range(projectile_count):
			var laser:Laser = preload("res://abilities/weapon/pulse_laser/laser.tscn").instantiate()
			get_viewport().get_camera_2d().add_child(laser)
			laser.damage_amount = damage_amount
			laser.global_position = muzzle_pos
			laser.global_rotation = muzzle_dir.angle()
			laser.length = projectile_speed
			laser.source = get_parent()
			laser.fire()
	
	else:
		
		for n:int in range(projectile_count):
			var target:CollisionObject2D = $ArcDetector.detected.keys().pick_random()
			var target_theta = ($ArcDetector.detected[target].position-muzzle_pos).angle()
			
			var laser:Laser = preload("res://abilities/weapon/pulse_laser/laser.tscn").instantiate()
			get_tree().current_scene.add_child(laser)
			laser.damage_amount = damage_amount
			laser.global_position = muzzle_pos
			laser.global_rotation = target_theta
			laser.length = projectile_speed
			laser.fire()
