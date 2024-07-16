extends AutoFireAbility

var damage:Stat = Stat.new(20, 0, INF)
var projectile_count:Stat = Stat.new(1, 1, INF, Stat.PERIODIC)
var laser_range:Stat = Stat.new(1000, 10, INF)
var auto_aim:Stat = Stat.new(15, 0, 90)

func _on_fired() -> void:
	var muzzle_pos:Vector2 = get_parent().get_muzzle_position()
	var muzzle_dir:Vector2 = get_parent().get_muzzle_direction()
	
	$ArcDetector.max_angle = deg_to_rad(auto_aim.get_value())
	$ArcDetector.max_range = laser_range.get_value()
	$ArcDetector.update_detected()
	$ArcDetector.global_position = muzzle_pos
	
	if($ArcDetector.detected.is_empty()):
	
		for n:int in range(projectile_count.get_value()):
			var laser:Laser = preload("res://abilities/weapon/pulse_laser/laser.tscn").instantiate()
			get_viewport().get_camera_2d().add_child(laser)
			laser.damage_amount = damage.get_value()
			laser.global_position = muzzle_pos
			laser.global_rotation = muzzle_dir.angle()
			laser.length = laser_range.get_value()
			laser.source = get_parent()
			laser.fire()
	
	else:
		
		for n:int in range(projectile_count.get_value()):
			var target:CollisionObject2D = $ArcDetector.detected.keys().pick_random()
			var target_theta = ($ArcDetector.detected[target].position-muzzle_pos).angle()
			
			var laser:Laser = preload("res://abilities/weapon/pulse_laser/laser.tscn").instantiate()
			get_tree().current_scene.add_child(laser)
			laser.damage_amount = damage.get_value()
			laser.global_position = muzzle_pos
			laser.global_rotation = target_theta
			laser.length = laser_range.get_value()
			laser.fire()
