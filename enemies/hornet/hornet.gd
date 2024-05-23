extends Enemy

## Time between shots (seconds).
@export var fire_delay:float = 2
## How long shots take to charge 
@export var charge_delay:float = 3
var fire_timer:CountdownTimer = CountdownTimer.new()
var charging_shot:Projectile
var is_charging:bool = false

@export var max_thrust:float
@export var max_torque:float

## Desired distance from the target player
@export var base_distance:float = 512

func _physics_process(delta: float) -> void:
	
	var target:Player = Player.find_nearest_player(position)
	if(is_instance_valid(target)):
		
		var desired_position:Vector2 = ((global_position)-target.global_position).normalized()*base_distance + target.global_position + $RandomWalk.position
		var desired_angle:float = (target.global_position-global_position).angle()
		
		var target_vel:Vector2 = target.get_average_velocity()
		var target_acc:Vector2 = target.get_average_acceleration()
		var thrust:Vector2 = Ballistics.find_thrust_to_position(global_position, self.linear_velocity, Vector2.ZERO, 
			desired_position, target_vel, target_acc, max_thrust)
		$'.'.apply_central_force(thrust)
		var torque:float = Ballistics.find_torque_to_angle(global_rotation, self.angular_velocity, desired_angle, max_torque)
		$'.'.apply_torque(torque)
		
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
				charging_shot.top_level=true
				charging_shot.global_transform = $Marker2D.global_transform
				charging_shot.linear_velocity = 200 * Vector2.from_angle(global_rotation) + self.linear_velocity
				var interp:Interpolator = charging_shot.get_node(^'Interpolator')
				interp.target = charging_shot
				interp.offset_target = null
				interp.offset = Transform2D.IDENTITY
				charging_shot = null
				fire_timer.time = fire_delay
				is_charging = false
