extends Enemy

const base_distance:float = 512
const max_torque:float = 6
const max_thrust:float = 100
const max_speed:float = 800
const max_rot_speed:float = 10

const charge_dist_tolerance:float = 200
const charge_angle_tolerance:float = 1
const shot_angle_tolerance:float = 0.1

const shot_speed:float = 400

var target:Player
var body:RigidBody2D

enum{
	## The shield is closed, and the fire_cooldown hasn't yet elapsed
	STAGE_COOLDOWN,
	## The shield is closed, and ready to fire once the target is in range
	STAGE_READY,
	## The fire_cooldown has elapsed, and the shield is in the process of opening
	STAGE_OPEN,
	## The shield is open, only a final adjustment to the rotation is needed before firing
	STAGE_FULLY_OPEN,
	## The projectile has fired, and the shield is now closing
	STAGE_CLOSE,
	## The projectile has not fired, but the shield is closing because the target is invalid or out of range
	STAGE_ABORT}
var fire_stage:int = STAGE_COOLDOWN

func _init()->void:
	super()
	body = $'.'

func _ready()->void:
	$AvoidanceAgent.max_speed = max_speed

func _physics_process(delta: float) -> void:
	target = Player.find_nearest_player(global_position)
	
	var target_in_range:bool = false
	var target_in_shot_range:bool = false
	if(is_instance_valid(target)):
		var sol:Dictionary = Ballistics.solve_linear_intercept(global_position, shot_speed, target.global_position, 
															   target.get_average_velocity()-body.linear_velocity)
		
		var desired_angle:float = sol.velocity.angle()
		var tsim:Dictionary = Ballistics.solve_torque(global_rotation, body.angular_velocity, max_torque, desired_angle, delta)
		body.angular_velocity = clamp(tsim.angular_velocity, -max_rot_speed, max_rot_speed)
		
		var tdist:float = (target.global_position-global_position).length()
		var dist_err:float = (target.global_position-global_position).length()-base_distance
		var angle_err:float = abs(angle_difference(desired_angle, global_rotation))
		target_in_range = dist_err<charge_dist_tolerance && angle_err<charge_angle_tolerance
		target_in_shot_range = angle_err<shot_angle_tolerance
	
	$RightShield.rotation =  ($ShieldTimer.duration-$ShieldTimer.time)/$ShieldTimer.duration * PI/4
	$LeftShield.rotation =  -($ShieldTimer.duration-$ShieldTimer.time)/$ShieldTimer.duration * PI/4
	
	match fire_stage:
		STAGE_COOLDOWN:
			if(!$CooldownTimer.running):
				$CooldownTimer.reset()
				$CooldownTimer.start()
		
		STAGE_READY:
			if(target_in_range):
				$ShieldTimer.reverse=true
				$ShieldTimer.start()
				fire_stage = STAGE_OPEN
		
		STAGE_OPEN:
			if(!target_in_range):
				$ShieldTimer.reverse=false
				fire_stage = STAGE_ABORT
		
		STAGE_FULLY_OPEN:
			if(target_in_shot_range):
				fire_projectile()
				fire_stage = STAGE_CLOSE
				$ShieldTimer.reverse = false
				$ShieldTimer.start()
			elif(!target_in_range):
				$ShieldTimer.reverse=false
				$ShieldTimer.start()
				fire_stage = STAGE_ABORT
		
		STAGE_ABORT:
			if(target_in_range):
				$ShieldTimer.reverse=true
				fire_stage = STAGE_OPEN

func fire_projectile()->void:
	var proj:Projectile = preload("res://enemies/shield_bearer/shield_bearer_projectile.tscn").instantiate()
	proj.global_position = global_position
	proj.linear_velocity = Vector2.RIGHT.rotated(global_rotation)*shot_speed + self.linear_velocity
	proj.global_rotation = global_rotation
	proj.source = self
	get_tree().current_scene.add_child(proj)

func _on_cooldown_timer_timeout() -> void:
	fire_stage = STAGE_READY


func _on_avoidance_agent_pre_update() -> void:
	if(is_instance_valid(target)):
		
		var tdir:Vector2 = (global_position-target.global_position).normalized()
		
		
		var tpos_a:Vector2 = (global_position-target.global_position).normalized()*base_distance + target.global_position
		var tpos_b:Vector2 = -Vector2.from_angle(global_rotation)*base_distance + target.global_position
		var t:float = (Vector2.from_angle(global_rotation).dot(tdir)+1)/2
		var tpos:Vector2 = tpos_a.slerp(tpos_b, t)
		
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


func _on_shield_timer_timeout() -> void:
	if($ShieldTimer.reverse):
		fire_stage = STAGE_FULLY_OPEN
	else:
		match fire_stage:
			STAGE_ABORT:
				fire_stage = STAGE_READY
			STAGE_CLOSE:
				fire_stage = STAGE_COOLDOWN
