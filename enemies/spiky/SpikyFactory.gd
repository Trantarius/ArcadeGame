class_name SpikyFactory
extends Enemy

const thrust:float = 100
const rot_speed:float = 1
const torque:float = 1

var body:RigidBody2D

func _init()->void:
	super()
	body = $'.'

func _physics_process(delta: float) -> void:
	body.angular_velocity += clamp(rot_speed-body.angular_velocity, -torque*delta, torque*delta)
	body.linear_velocity -= body.linear_velocity.limit_length(thrust*delta)

func _on_spawn_timer_timeout() -> void:
	var dir:Vector2 = Vector2.from_angle(randf()*TAU)
	var spiky:Spiky = preload("res://enemies/spiky/spiky.tscn").instantiate()
	spiky.global_position = position + dir * 32
	spiky.linear_velocity = dir * 200
	spiky.add_collision_exception_with(self)
	get_tree().current_scene.add_child(spiky)
