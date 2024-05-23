extends WeaponAbility

## Standard deviation of shot angle
const innaccuracy:float = deg_to_rad(1)

func _on_fire() -> void:
	
	var muzzle_pos:Vector2 = get_parent().get_muzzle_position()
	var muzzle_dir:Vector2 = get_parent().get_muzzle_direction()
	
	var cone:ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	cone.points = [
		(Vector2.RIGHT*projectile_speed).rotated(-deg_to_rad(projectile_size)),
		(Vector2.RIGHT*projectile_speed),
		(Vector2.RIGHT*projectile_speed).rotated(deg_to_rad(projectile_size)),
		Vector2.ZERO]
	
	var query:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.collision_mask = 0b100 # Enemy  collision layer
	query.shape = cone
	query.transform = Transform2D(muzzle_dir.angle(),muzzle_pos)
	var result:Array[Dictionary] = get_viewport().find_world_2d().direct_space_state.intersect_shape(query)
	
	if(result.is_empty()):
	
		for n:int in range(projectile_count):
			var laser:Laser = preload("res://abilities/weapon/pulse_laser/laser.tscn").instantiate()
			get_viewport().get_camera_2d().add_child(laser)
			laser.damage_amount = damage_amount
			laser.global_position = muzzle_pos
			laser.global_rotation = muzzle_dir.angle() + randfn(0,innaccuracy)
			laser.length = projectile_speed
			laser.source = get_parent()
			laser.fire()
	
	else:
		
		for n:int in range(projectile_count):
			var target:Enemy = result.pick_random().collider
			var target_theta = (target.global_position-muzzle_pos).angle()
			var leftlimit_theta:float = muzzle_dir.angle() - deg_to_rad(projectile_size)
			var rightlimit_theta:float = muzzle_dir.angle() + deg_to_rad(projectile_size)
			target_theta = Util.angle_clamp(target_theta, leftlimit_theta, rightlimit_theta)
			
			var laser:Laser = preload("res://abilities/weapon/pulse_laser/laser.tscn").instantiate()
			get_viewport().get_camera_2d().add_child(laser)
			laser.damage_amount = damage_amount
			laser.global_position = muzzle_pos
			laser.global_rotation = target_theta + randfn(0,innaccuracy)
			laser.length = projectile_speed
			laser.fire()
