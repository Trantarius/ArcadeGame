extends Enemy

## Time between shots (seconds).
@export var fire_delay:float = 2
## How long shots take to charge 
@export var charge_delay:float = 3
var fire_timer:CountdownTimer = CountdownTimer.new()
var charging_shot:Projectile
var is_charging:bool = false

## Desired distance from the target player
@export var base_distance:float = 512

var target:Player

func _physics_process(delta: float) -> void:
	
	target = Player.find_nearest_player(position)
	if(is_instance_valid(target)):
		var desired_angle:float = (target.global_position-global_position).angle()
		
		# reverse the charging if too far or facing the wrong direction
		var tdist:float = (target.global_position-global_position).length()
		fire_timer.reverse = ((tdist>3*base_distance/2 || abs(angle_difference(global_rotation,desired_angle))>1)
							 && is_charging)
	else:
		fire_timer.reverse=is_charging
	
	if(!is_charging):
		if(is_instance_valid(charging_shot)):
			charging_shot.queue_free()
			charging_shot = null
		if(fire_timer.time<=0):
			is_charging = true
			fire_timer.time = charge_delay
			charging_shot = preload("res://enemies/hornet/hornet_shot.tscn").instantiate()
			var interp:Interpolator = charging_shot.get_node(^'Interpolator')
			interp.target = self
			interp.offset_target = charging_shot
			charging_shot.transform = $Marker2D.transform
			charging_shot.source = self
			add_child(charging_shot)
			charging_shot.transform = $Marker2D.transform
			
	
	else:
		if(!is_instance_valid(charging_shot)):
			is_charging = false
			fire_timer.time = fire_delay
		else:
			fire_timer.time = min(charge_delay,fire_timer.time)
			charging_shot.global_scale = Vector2.ONE * (charge_delay-fire_timer.time)/charge_delay
			charging_shot.global_position = $Marker2D.global_position
			if(fire_timer.time<=0):
				charging_shot.reparent(get_tree().current_scene)
				charging_shot.global_transform = $Marker2D.global_transform
				charging_shot.linear_velocity = 200 * Vector2.from_angle(global_rotation) + self.linear_velocity
				var interp:Interpolator = charging_shot.get_node(^'Interpolator')
				interp.target = charging_shot
				interp.offset_target = null
				interp.offset = Transform2D.IDENTITY
				charging_shot = null
				fire_timer.time = fire_delay
				is_charging = false


func _on_ballistic_ai_pre_update() -> void:
	$BallisticAI.linear_velocity = $'.'.linear_velocity
	$BallisticAI.angular_velocity = $'.'.angular_velocity
	if(is_instance_valid(target)):
		var desired_position:Vector2 = ((global_position)-target.global_position).normalized()*base_distance + target.global_position + $RandomWalk.position
		$BallisticAI.target_position = desired_position
		$BallisticAI.target_velocity = target.get_average_velocity()
		$BallisticAI.target_acceleration = target.get_average_acceleration()


func _on_ballistic_ai_post_update() -> void:
	if(is_instance_valid(target)):
		var desired_angle:float = (target.global_position-global_position).angle()
		$'.'.apply_central_force($BallisticAI.force*self.mass)
		$'.'.apply_torque(Ballistics.find_torque_to_angle(global_rotation,self.angular_velocity, desired_angle, $BallisticAI.max_angular_thrust)*
			PhysicsServer2D.body_get_param($'.'.get_rid(),PhysicsServer2D.BODY_PARAM_INERTIA))
