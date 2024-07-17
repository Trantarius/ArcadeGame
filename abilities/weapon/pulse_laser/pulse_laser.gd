extends PlayerAbility

var fire_rate:Stat = Stat.new(2, 0, INF)
var damage:Stat = Stat.new(20, 0, INF)
var projectile_count:Stat = Stat.new(1, 1, INF, Stat.PERIODIC)
var laser_range:Stat = Stat.new(1000, 10, INF)
var auto_aim:Stat = Stat.new(15, 0, 90)

signal fired

func _ready()->void:
	$FireTimer.duration = 1.0/fire_rate.get_value()
	$FireTimer.reset()
	$FireTimer.start()

func _on_fire_timer_timeout_precise(ago: float) -> void:
	var lin_err:Vector2 = -get_parent().linear_velocity * ago
	var ang_err:float = -get_parent().angular_velocity * ago
	var muzzle_pos:Vector2 = (get_parent().get_muzzle_position() - get_parent().global_position
		).rotated(ang_err) + get_parent().global_position + lin_err
	var muzzle_dir:Vector2 = get_parent().get_muzzle_direction().rotated(ang_err)
	
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
	
	fired.emit()
	$FireTimer.duration = 1.0/fire_rate.get_value()
