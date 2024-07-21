extends Enemy

@export var cannon_fire_delay:float = 5

## The amount of force used in the direction parallel to the ship to move it.
const max_thrust:float = 100
## Damps velocity perpendicular to the ship's heading.
const keel_strength:float = 10
const keel_drag:float = 10
const max_distance:float = 1500
const approach_distance:float = 750

const min_speed:float = 50
const max_speed:float = 400

const max_rot_speed:float = 0.1
const max_torque:float = 1

var target:Player
var body:RigidBody2D

func _init()->void:
	body = $'.'

func _ready() -> void:
	$PortFireTimer.duration = cannon_fire_delay
	$PortFireTimer.reset()
	$PortFireTimer.start()
	$StarboardFireTimer.duration = cannon_fire_delay
	$StarboardFireTimer.reset()
	$StarboardFireTimer.start()
	
	max_health.base = 0
	for child:Node in ($Port/Turrets.get_children() + $Port/Cannons.get_children() + 
					   $Starboard/Turrets.get_children() + $Starboard/Cannons.get_children() +
					   [$Engine, $Engine2]):
		$'.'.add_collision_exception_with(child)
		child.add_collision_exception_with(self)
		child.damage_taken.connect(_on_part_damaged, CONNECT_DEFERRED)
		max_health.base += child.max_health

func _on_part_damaged(damage:Damage)->void:
	damage.silent=true
	take_damage(damage)

func _physics_process(_delta: float) -> void:
	
	if($PortFireTimer.is_finished()):
		var fire_port:bool = false
		for cannon:Enemy in $Port/Cannons.get_children():
			if(!cannon.get_node(^'Detector').get_overlapping_bodies().is_empty()):
				fire_port=true
				break
		if(fire_port):
			for cannon:Enemy in $Port/Cannons.get_children():
				cannon.fire()
			$PortFireTimer.reset()
			$PortFireTimer.start()
	
	if($StarboardFireTimer.is_finished()):
		var fire_starboard:bool = false
		for cannon:Enemy in $Starboard/Cannons.get_children():
			if(!cannon.get_node(^'Detector').get_overlapping_bodies().is_empty()):
				fire_starboard=true
				break
		if(fire_starboard):
			for cannon:Enemy in $Starboard/Cannons.get_children():
				cannon.fire()
			$StarboardFireTimer.reset()
			$StarboardFireTimer.start()
	
	target = Player.find_nearest_player(global_position)
	

func _on_avoidance_agent_pre_update() -> void:
	
	var velocity:Vector2 = body.linear_velocity
	
	var forward:Vector2 = Vector2.from_angle(global_rotation)
	var across:Vector2 = forward.orthogonal()
	
	var keel_v:float = velocity.dot(across)
	velocity -= across*keel_v*get_physics_process_delta_time()*keel_strength
	velocity -= abs(keel_v)*sign(velocity.dot(forward))*forward*keel_drag*get_physics_process_delta_time()
	
	var dspeed:float
	var heading:float
	if(is_instance_valid(target)):
		var tpos:Vector2 = target.global_position - global_position
		var tdist:float = tpos.length()
		
		var app_angle:float = asin(approach_distance/tdist)
		heading = sign(angle_difference(tpos.angle(),forward.angle()))*app_angle + tpos.angle()
		
		var tside:float = sign(tpos.dot(across))
		
		if(tdist>max_distance):
			
			dspeed = lerp(min_speed, max_speed, max(0,forward.dot(Vector2.from_angle(heading)))**2)
			var bt:float = (max_speed-min_speed)/max_thrust
			var bd:float = max_speed*bt - 0.5 * max_thrust * bt**2
			dspeed = lerp(dspeed, min_speed, clamp(remap(tdist, max_distance+bd, max_distance, 0, 1),0,1))
			
		else:
			dspeed=min_speed
			heading = forward.angle()
	
	else:
		dspeed = min_speed
		heading = forward.angle()
	
	var speed_err:float = dspeed-velocity.dot(forward)
	velocity += sign(dspeed-velocity.dot(forward))*forward*max_thrust*get_physics_process_delta_time()
	velocity = velocity.limit_length(max_speed)
	
	var sol:Dictionary = Ballistics.solve_torque(global_rotation, body.angular_velocity, max_torque, heading, get_physics_process_delta_time())
	body.angular_velocity = clamp(sol.angular_velocity, -max_rot_speed, max_rot_speed)
	
	$AvoidanceAgent.velocity = velocity
	await $AvoidanceAgent.post_update
	velocity = $AvoidanceAgent.velocity
	
	body.linear_velocity = velocity
