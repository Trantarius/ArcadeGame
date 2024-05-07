class_name Interpolator
extends Node2D

func _enter_tree()->void:
	top_level=true
	RenderingServer.frame_pre_draw.connect(update)

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(update)

func update() -> void:
	var now:int = Time.get_ticks_usec()
	var dt:float = Engine.get_physics_interpolation_fraction()/Engine.physics_ticks_per_second
	global_position = get_parent().global_position + get_parent().linear_velocity * dt
	global_rotation = get_parent().global_rotation + get_parent().angular_velocity * dt
	global_scale = get_parent().global_scale
