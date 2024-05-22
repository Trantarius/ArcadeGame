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

func _ready()->void:
	fire_timer.max_time = charge_delay
	fire_timer.min_time = 0

func _physics_process(delta: float) -> void:
	
	var target:Player = Player.find_nearest_player(position)
	if(is_instance_valid(target)):
		
		var desired_position:Vector2 = ((position)-target.position).normalized()*base_distance + target.position + $RandomWalk.position
		var desired_angle:float = (target.position-position).angle()
		
		var thrust:Vector2 = Ballistics.find_thrust_to_position(global_position, self.linear_velocity, Vector2.ZERO, 
			desired_position, target.get_average_velocity(), target.get_average_acceleration(), max_thrust)
		$'.'.apply_force(thrust)
		$'.'.apply_torque(Ballistics.find_torque_to_angle(global_rotation, self.angular_velocity, desired_angle, max_torque))
		
		# reverse the charging if too far or facing the wrong direction
		var tdist:float = (target.position-position).length()
		fire_timer.reverse = ((tdist>3*base_distance/2 || abs(angle_difference(rotation,desired_angle))>1)
							 && is_charging)
		
	
	if(is_instance_valid(charging_shot)):
		charging_shot.scale = Vector2.ONE * (charge_delay-fire_timer.time)/charge_delay
		var interp:Interpolator = charging_shot.get_node(^'Interpolator')
		interp.linear_velocity_override = self.linear_velocity + self.angular_velocity * $Marker2D.position.orthogonal()
		interp.angular_velocity_override = self.angular_velocity
		if(fire_timer.time<=0):
			fire()
			fire_timer.time = fire_delay
			is_charging=false
	elif(is_charging):
		is_charging=false
		fire_timer.time = fire_delay
	elif(fire_timer.time<=0):
		make_new_shot()
		is_charging=true
		

func make_new_shot()->void:
	if(is_instance_valid(charging_shot)):
		charging_shot.queue_free()
	charging_shot=preload("res://enemies/hornet/hornet_shot.tscn").instantiate()
	add_child(charging_shot)
	charging_shot.position=$Marker2D.position
	charging_shot.source=self
	charging_shot.scale = Vector2.ZERO

func fire()->void:
	charging_shot.reparent(get_parent())
	charging_shot.linear_velocity = 200 * global_transform.basis_xform(Vector2.RIGHT).normalized() + self.linear_velocity
	var interp:Interpolator = charging_shot.get_node(^'Interpolator')
	interp.linear_velocity_override = null
	interp.angular_velocity_override = null
	charging_shot=null
