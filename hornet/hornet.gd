extends Enemy

## Time between shots (seconds).
const fire_delay:float = 4
var fire_timer = 0
var charging_shot:Projectile

## Desired distance from the target player
const base_distance:float = 512

func _ready()->void:
	make_new_shot()

func _physics_process(delta: float) -> void:
	
	var target:Player = find_nearest_player()
	if(target==null):
		linear_control_mode = ControlMode.THRUST
		linear_target = Vector2.ZERO
		angular_control_mode = ControlMode.THRUST
		angular_target = 0
		fire_timer = max(0,fire_timer-delta)
	else:
		
		linear_control_mode = ControlMode.POSITION
		linear_target = ((position)-target.position).normalized()*base_distance + target.position + $RandomWalk.position
		
		angular_control_mode = ControlMode.POSITION
		angular_target = (target.position-position).angle()
		
		reference_velocity = target.linear_velocity
		reference_acceleration = target.linear_acceleration
		
		var tdist:float = (target.position-position).length()
		if(tdist>base_distance/2 && tdist<3*base_distance/2):
			fire_timer+=delta
		else:
			fire_timer = max(0,fire_timer-delta)
		
	if(!is_instance_valid(charging_shot)):
		make_new_shot()
		
	charging_shot.scale = Vector2.ONE*fire_timer/fire_delay
	if(fire_timer>fire_delay):
		fire()
		fire_timer-=fire_delay

func make_new_shot()->void:
	if(is_instance_valid(charging_shot)):
		charging_shot.queue_free()
	charging_shot=preload("res://hornet/hornet_shot.tscn").instantiate()
	add_child(charging_shot)
	charging_shot.position=$Marker2D.position
	charging_shot.source=self
	charging_shot.hit.connect(on_charging_shot_hit)

func on_charging_shot_hit(_collision:KinematicCollision2D)->void:
	fire_timer=0
	make_new_shot()

func fire()->void:
	charging_shot.reparent(get_parent())
	charging_shot.velocity = 200 * global_transform.basis_xform(Vector2.RIGHT).normalized() + linear_velocity
	charging_shot.hit.disconnect(on_charging_shot_hit)
	charging_shot=null
	make_new_shot()
