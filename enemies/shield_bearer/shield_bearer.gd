extends Enemy

const base_distance:float = 256
const max_torque:float = 1
const max_thrust:float = 100
const max_speed:float = 800
const max_rot_speed:float = 0.5

var target:Player
var body:RigidBody2D


func _init()->void:
	super()
	body = $'.'

func _ready()->void:
	$AvoidanceAgent.max_speed = max_speed

func _physics_process(delta: float) -> void:
	target = Player.find_nearest_player(global_position)
	
	if(is_instance_valid(target)):
		
		var desired_angle:float = (target.global_position-global_position).angle()
		var tsim:Dictionary = Ballistics.solve_torque(global_rotation, body.angular_velocity, max_torque, desired_angle, delta)
		body.angular_velocity = clamp(tsim.angular_velocity, -max_rot_speed, max_rot_speed)


func _on_avoidance_agent_pre_update() -> void:
	if(is_instance_valid(target)):
		
		var tdir:Vector2 = (global_position-target.global_position).normalized()
		
		var tpos:Vector2 = target.global_position - Vector2.from_angle(global_rotation) * base_distance
		
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

