class_name Spiky
extends Enemy

var target:Player
var body:RigidBody2D

const max_speed:float = 800
const max_rot_speed:float = 6
const max_thrust:float = 200

func _init()->void:
	super()
	body = $'.'

func _ready()->void:
	$AvoidanceAgent.max_speed = max_speed

func _physics_process(_delta: float) -> void:
	target = Player.find_nearest_player(position)

func _on_hit_box_damage_dealt(_damage: Damage) -> void:
	queue_free()

func _on_avoidance_agent_pre_update() -> void:
	target = Player.find_nearest_player(position)
	var next_velocity:Vector2
	if(is_instance_valid(target)):
		var intercept:Dictionary = Ballistics.solve_quadratic_intercept(global_position, body.linear_velocity, max_thrust, 
									target.global_position, target.get_average_velocity(), target.get_average_acceleration())
		next_velocity = body.linear_velocity + intercept.acceleration * get_physics_process_delta_time()
	else:
		next_velocity = body.linear_velocity
	next_velocity = next_velocity.limit_length(max_speed)
	$AvoidanceAgent.velocity = next_velocity
	await $AvoidanceAgent.post_update
	next_velocity = $AvoidanceAgent.velocity
	var acc:Vector2 = (next_velocity - body.linear_velocity)/get_physics_process_delta_time()
	var turn_amount:float = (acc/max_thrust).dot(body.linear_velocity.orthogonal()/max_speed)
	body.angular_velocity = turn_amount * max_rot_speed
	body.linear_velocity = next_velocity
