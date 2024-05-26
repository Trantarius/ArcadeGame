extends Enemy

@export var turn_rate:float = 1
@export var fire_delay:float = 1
@export var shot_speed:float = 400

var fire_timer:CountdownTimer = CountdownTimer.new()
var target:Actor

func _physics_process(delta: float) -> void:
	
	if(!is_instance_valid(target)):
		$Barrel.global_rotation = rotate_toward($Barrel.global_rotation, $Detector.global_rotation, turn_rate*delta)
		return
		
	var shot_dir:Vector2 = Ballistics.aim_shot_linear(global_position, get_average_velocity(), 
		target.global_position, target.get_average_velocity(), shot_speed)
	var shot_angle:float = Util.angle_clamp(shot_dir.angle(), global_rotation-$Detector.max_angle, global_rotation+$Detector.max_angle)
	
	$Barrel.global_rotation = rotate_toward($Barrel.global_rotation, shot_angle, turn_rate*delta)
	
	if(abs(angle_difference($Barrel.global_rotation,shot_angle))<0.1 && fire_timer.time<=0):
		fire()
		fire_timer.time = fire_delay

func fire()->void:
	var proj:Projectile = preload("res://enemies/broadside/turret_projectile.tscn").instantiate()
	proj.top_level=true
	proj.global_position = $Barrel/Muzzle.global_position
	proj.linear_velocity = Vector2.from_angle($Barrel.global_rotation)*shot_speed + get_average_velocity()
	proj.source = self
	get_tree().current_scene.add_child(proj)

func _on_detector_body_entered(body: Node2D) -> void:
	if(body is Actor && !is_instance_valid(target)):
		target=body

func _on_detector_body_exited(body: Node2D) -> void:
	if(body==target):
		target=null
		var detected:Array[Node2D] = $Detector.get_overlapping_bodies()
		while(!(target is Actor) && !detected.is_empty()):
			detected.erase(target)
			target = detected.pick_random()
		if(detected.is_empty()):
			target=null
			
