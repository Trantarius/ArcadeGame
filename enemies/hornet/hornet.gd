extends Enemy

## Time between shots (seconds).
const fire_delay:float = 4
## How long shots take to charge (must be less than fire_delay)
const charge_delay:float = 3
var fire_timer:CountdownTimer = CountdownTimer.new()
var charging_shot:Projectile

## Desired distance from the target player
const base_distance:float = 512

func _ready()->void:
	fire_timer.max_time = fire_delay
	fire_timer.min_time = 0

func _physics_process(delta: float) -> void:
	
	var target:Player = Player.find_nearest_player(position)
	if(target==null):
		linear_control_mode = ControlMode.THRUST
		linear_target = Vector2.ZERO
		angular_control_mode = ControlMode.THRUST
		angular_target = 0
		fire_timer.reverse = true
	else:
		
		linear_control_mode = ControlMode.POSITION
		linear_target = ((position)-target.position).normalized()*base_distance + target.position + $RandomWalk.position
		
		angular_control_mode = ControlMode.POSITION
		angular_target = (target.position-position).angle()
		
		reference_velocity = target.linear_velocity
		reference_acceleration = target.linear_acceleration
		
		# reverse the charging if too far or facing the wrong direction
		var tdist:float = (target.position-position).length()
		fire_timer.reverse = ((tdist>3*base_distance/2 || abs(angle_difference(rotation,angular_target))>1)
							 && fire_timer.time<charge_delay)
		
	
	if(is_instance_valid(charging_shot)):
		if(fire_timer.time > charge_delay):
			charging_shot.queue_free()
			charging_shot=null
		else:
			charging_shot.scale = Vector2.ONE * (charge_delay-fire_timer.time)/charge_delay
			var interp:Interpolator = charging_shot.get_node(^'Interpolator')
			interp.linear_velocity_override = linear_velocity + angular_velocity * $Marker2D.position.orthogonal()
			interp.angular_velocity_override = angular_velocity
			if(fire_timer.time<=0 && abs(angle_difference(rotation,angular_target))<0.1):
				fire()
				fire_timer.time = fire_delay
	elif(fire_timer.time<=charge_delay):
		make_new_shot()

func make_new_shot()->void:
	if(is_instance_valid(charging_shot)):
		charging_shot.queue_free()
	charging_shot=preload("res://enemies/hornet/hornet_shot.tscn").instantiate()
	add_child(charging_shot)
	charging_shot.position=$Marker2D.position
	charging_shot.source=self
	charging_shot.hit.connect(on_charging_shot_hit)
	charging_shot.scale = Vector2.ZERO

func on_charging_shot_hit(_collision:KinematicCollision2D)->void:
	fire_timer.time = fire_delay

func fire()->void:
	charging_shot.reparent(get_parent())
	charging_shot.linear_velocity = 200 * global_transform.basis_xform(Vector2.RIGHT).normalized() + reference_velocity
	charging_shot.hit.disconnect(on_charging_shot_hit)
	var interp:Interpolator = charging_shot.get_node(^'Interpolator')
	interp.linear_velocity_override = null
	interp.angular_velocity_override = null
	charging_shot=null
