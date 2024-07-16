extends Enemy


const base_distance:float = 512
const wander_distance:float = 128
const wander_rate:float = 64
const max_torque:float = 6
const max_thrust:float = 100
const max_speed:float = 800
const max_rot_speed:float = 10

const charge_dist_tolerance:float = 200
const charge_angle_tolerance:float = 1
const shoot_angle_tolerance:float = 0.1

const shot_speed:float = 200

var wander_prev:Vector2
var wander_next:Vector2
var target:Player
var body:RigidBody2D
var charging_shot:Projectile

func _init()->void:
	body = $'.'

func _ready()->void:
	$AvoidanceAgent.max_speed = max_speed

func _physics_process(delta: float) -> void:
	
	if(($ChargeTimer.running || $ChargeTimer.time==0) && !is_instance_valid(charging_shot)):
		# something happened to the shot, it probably hit something
		$ChargeTimer.stop()
		$ChargeTimer.reset()
		$FireTimer.reset()
		$FireTimer.start()
	
	target = Player.find_nearest_player(position)
	if(is_instance_valid(target)):
		
		var sol:Dictionary = Ballistics.solve_linear_intercept(global_position, shot_speed, target.global_position, target.get_average_velocity()-body.linear_velocity)
		
		var desired_angle:float = sol.velocity.angle()
		var tsim:Dictionary = Ballistics.solve_torque(global_rotation, body.angular_velocity, max_torque, desired_angle, delta)
		body.angular_velocity = clamp(tsim.angular_velocity, -max_rot_speed, max_rot_speed)
		
		# reverse the charging if too far or facing the wrong direction
		var tdist:float = (target.global_position-global_position).length()
		var dist_err:float = abs((target.global_position-global_position).length()-base_distance)
		var angle_err:float = abs(angle_difference(desired_angle, global_rotation))
		var charge:bool = !(dist_err>charge_dist_tolerance || angle_err>charge_angle_tolerance)
		$ChargeTimer.reverse = !charge
		
		if($ChargeTimer.time==0):
			if(angle_err<shoot_angle_tolerance):
				shoot()
				$ChargeTimer.reset()
			elif(!charge):
				$ChargeTimer.reverse=false
				$ChargeTimer.start()
		
		elif(charge && $FireTimer.is_finished() && !$ChargeTimer.running):
			create_shot()
			
	else:
		$ChargeTimer.reverse=true
	
	if(is_instance_valid(charging_shot)):
		charging_shot.global_scale = Vector2.ONE * ($ChargeTimer.duration-$ChargeTimer.time)/$ChargeTimer.duration
		charging_shot.global_position = $Marker2D.global_position
	
	if(!$FireTimer.is_finished() && !$FireTimer.running):
		$FireTimer.reset()
		$FireTimer.start()


func _on_avoidance_agent_pre_update() -> void:
	if(is_instance_valid(target)):
		
		if(!$WanderTimer.running):
			wander_prev=wander_next
			wander_next = lerp(wander_prev, Vector2.from_angle(randf()*TAU)*wander_distance, randf_range(0.1,0.9))
			$WanderTimer.duration = (wander_next-wander_prev).length()/wander_rate
			$WanderTimer.reset()
			$WanderTimer.start()
		var wander:Vector2 = lerp(wander_prev, wander_next, $WanderTimer.time/$WanderTimer.duration)
		var tpos:Vector2 = (global_position-target.global_position).normalized()*base_distance + target.global_position + wander
		var tvel:Vector2 = target.get_average_velocity()
		var acc:Vector2 = Ballistics.solve_rendezvous(global_position, body.linear_velocity, max_thrust, tpos, tvel)
		var next_linvel:Vector2 = (body.linear_velocity + acc*get_physics_process_delta_time()).limit_length(max_speed)
		$AvoidanceAgent.velocity = next_linvel
		await $AvoidanceAgent.post_update
		body.linear_velocity = $AvoidanceAgent.velocity
	
	else:
		$AvoidanceAgent.velocity = body.linear_velocity
		await $AvoidanceAgent.post_update
		body.linear_velocity = $AvoidanceAgent.velocity

func create_shot()->void:
	charging_shot = preload("res://enemies/hornet/hornet_shot.tscn").instantiate()
	var interp:Interpolator = charging_shot.get_node(^'Interpolator')
	interp.target = self
	interp.offset_target = charging_shot
	charging_shot.transform = $Marker2D.transform
	charging_shot.source = self
	add_child(charging_shot)
	charging_shot.transform = $Marker2D.transform
	$ChargeTimer.reset()
	$ChargeTimer.start()

func shoot()->void:
	if(is_instance_valid(charging_shot)):
		charging_shot.reparent(get_tree().current_scene)
		charging_shot.global_transform = $Marker2D.global_transform
		charging_shot.linear_velocity = shot_speed * Vector2.from_angle(global_rotation) + self.linear_velocity
		var interp:Interpolator = charging_shot.get_node(^'Interpolator')
		interp.target = charging_shot
		interp.offset_target = null
		interp.offset = Transform2D.IDENTITY
	charging_shot = null
	$FireTimer.reset()
	$FireTimer.start()

func abort_shot()->void:
	charging_shot.queue_free()
	charging_shot=null
	$ChargeTimer.reverse = false
	$ChargeTimer.reset()



func _on_charge_timer_timeout() -> void:
	if($ChargeTimer.reverse):
		abort_shot()
