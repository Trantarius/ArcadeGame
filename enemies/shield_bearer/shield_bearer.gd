extends Enemy

## Cooldown that must elapse (while the shield is closed) before firing again
@export var fire_cooldown:float = 4
## The time it takes for the shield to go from fully open to fully closed (or vice versa)
@export var shield_move_time:float = 2
## Desired distance from player
@export var base_distance:float = 512

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
		linear_control_mode = ControlMode.THRUST
		linear_target = Vector2.ZERO
		angular_control_mode = ControlMode.THRUST
		angular_target = 0
		match(fire_stage):
			STAGE_COOLDOWN:
				fire_timer.paused = true
			STAGE_OPEN:
				abort_open_stage()
		
	else:
		
		linear_control_mode = ControlMode.POSITION
		linear_target = ((global_position)-target.global_position).normalized()*base_distance + target.global_position
		
		angular_control_mode = ControlMode.POSITION
		angular_target = (target.global_position-global_position).angle()
		
		reference_velocity = target.linear_velocity
		reference_acceleration = target.linear_acceleration
		
		# reverse the charging if too far or facing the wrong direction
		var tdist:float = (target.global_position-global_position).length()
		
		if(tdist>3*base_distance/2 || abs(angle_difference(global_rotation,angular_target))>1):
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
	proj.linear_velocity = Vector2.RIGHT.rotated(global_rotation)*400 + reference_velocity
	proj.global_rotation = global_rotation
	proj.source = self
	get_parent().add_child(proj)

func abort_open_stage()->void:
	fire_stage = STAGE_ABORT
	fire_timer.time = shield_move_time-fire_timer.time
