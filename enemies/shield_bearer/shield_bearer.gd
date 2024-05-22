extends Enemy

## Cooldown that must elapse (while the shield is closed) before firing again
@export var fire_cooldown:float = 4
## The time it takes for the shield to go from fully open to fully closed (or vice versa)
@export var shield_move_time:float = 2
## Desired distance from player
@export var base_distance:float = 512

@export var max_thrust:float
@export var max_torque:float

var fire_timer:CountdownTimer=CountdownTimer.new()

enum{
	## The shield is closed, and the fire_cooldown hasn't yet elapsed
	STAGE_COOLDOWN,
	## The fire_cooldown has elapsed, and the shield is in the process of opening
	STAGE_OPEN,
	## The projectile has fired, and the shield is now closing
	STAGE_CLOSE,
	## The projectile has not fired, but the shield is closing because the target is invalid or out of range
	STAGE_ABORT}
var fire_stage:int = STAGE_COOLDOWN

func _ready() -> void:
	fire_timer.time = fire_cooldown

func _physics_process(_delta: float) -> void:
	var target:Player = Player.find_nearest_player(global_position)
	if(target==null):
		match(fire_stage):
			STAGE_COOLDOWN:
				fire_timer.paused = true
			STAGE_OPEN:
				abort_open_stage()
		
	else:
		
		var desired_position:Vector2 =  ((global_position)-target.global_position).normalized()*base_distance + target.global_position
		var desired_angle:float = (target.global_position-global_position).angle()
		
		var thrust:Vector2 = Ballistics.find_thrust_to_position(global_position,self.linear_velocity,Vector2.ZERO,
			desired_position, target.linear_velocity, Vector2.ZERO, max_thrust)
		$'.'.apply_force(thrust)
		$'.'.apply_torque(Ballistics.find_torque_to_angle(global_rotation, self.angular_velocity, desired_angle, max_torque))
		
		# reverse the charging if too far or facing the wrong direction
		var tdist:float = (target.global_position-global_position).length()
		
		if(tdist>3*base_distance/2 || abs(angle_difference(global_rotation,desired_angle))>1):
			match(fire_stage):
				STAGE_COOLDOWN:
					fire_timer.paused = true
				STAGE_OPEN:
					abort_open_stage()
		else:
			match(fire_stage):
				STAGE_COOLDOWN:
					fire_timer.paused=false
		
	if(fire_timer.time<=0):
		match(fire_stage):
			STAGE_COOLDOWN:
				fire_stage = STAGE_OPEN
				fire_timer.time = shield_move_time
			STAGE_OPEN:
				fire_stage = STAGE_CLOSE
				fire_timer.time = shield_move_time
				fire_projectile()
			STAGE_CLOSE:
				$RightShield.rotation = 0
				$LeftShield.rotation = 0
				fire_stage = STAGE_COOLDOWN
				fire_timer.time = fire_cooldown
			STAGE_ABORT:
				fire_stage = STAGE_COOLDOWN
				fire_timer.time = 0.01
				# if aborting, we presumably don't want to fire right now
				fire_timer.paused = true 
	
	match(fire_stage):
		STAGE_OPEN:
			$RightShield.rotation =  (shield_move_time-fire_timer.time)/shield_move_time * PI/4
			$LeftShield.rotation =  -(shield_move_time-fire_timer.time)/shield_move_time * PI/4
		STAGE_CLOSE, STAGE_ABORT:
			$RightShield.rotation =  fire_timer.time/shield_move_time * PI/4
			$LeftShield.rotation =  -fire_timer.time/shield_move_time * PI/4

func fire_projectile()->void:
	var proj:Projectile = preload("res://enemies/shield_bearer/shield_bearer_projectile.tscn").instantiate()
	proj.global_position = global_position
	proj.linear_velocity = Vector2.RIGHT.rotated(global_rotation)*400 + self.linear_velocity
	proj.global_rotation = global_rotation
	proj.source = self
	get_parent().add_child(proj)

func abort_open_stage()->void:
	fire_stage = STAGE_ABORT
	fire_timer.time = shield_move_time-fire_timer.time
