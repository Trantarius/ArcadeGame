extends Enemy

@export var turn_rate:float = 1
@export var fire_delay:float = 1

const shot_speed:float = 400

var fire_timer:CountdownTimer = CountdownTimer.new()
var target:Actor

func _ready() -> void:
	$Detector.global_transform = global_transform
	linear_target = position.rotated(get_parent().global_rotation)
	reference_position = get_parent().global_position
	reference_velocity = get_parent().linear_velocity
	reference_acceleration = get_parent().linear_acceleration

func _physics_process(delta: float) -> void:
	linear_target = position.rotated(get_parent().global_rotation)
	reference_position = get_parent().global_position
	reference_velocity = get_parent().linear_velocity
	reference_acceleration = get_parent().linear_acceleration
	
	if(!is_instance_valid(target)):
		angular_target = sign(angle_difference(rotation,$Detector.rotation))*turn_rate
		return
	
	var lead_time:float = (target.global_position-global_position).length()/shot_speed
	var target_pos:Vector2 = target.global_position + target.linear_velocity * lead_time
	var target_theta:float = (target_pos - global_position).angle()
	angular_target = sign(angle_difference(rotation,target_theta))*turn_rate
	
	if(abs(angle_difference(rotation,target_theta))<0.1 && fire_timer.time<=0):
		fire()
		fire_timer.time = fire_delay

func fire()->void:
	var proj:Projectile = preload("res://enemies/broadside/turret_projectile.tscn").instantiate()
	proj.top_level=true
	proj.global_position = $Muzzle.global_position
	proj.linear_velocity = Vector2.RIGHT.rotated($Muzzle.global_rotation)*shot_speed
	proj.source = self
	add_child(proj)

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
			
