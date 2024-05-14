class_name Interpolator
extends Node2D

enum{IGNORE=0,TRACK=1,INTERPOLATE=2}
@export_enum('Ignore:0','Track:1','Interpolate:2') var position_behavior:int = INTERPOLATE
@export_enum('Ignore:0','Track:1','Interpolate:2') var rotation_behavior:int = INTERPOLATE
@export_enum('Ignore:0','Track:1','Interpolate:2') var scale_behavior:int = INTERPOLATE

func _ready()->void:
	top_level = true

func _enter_tree()->void:
	RenderingServer.frame_pre_draw.connect(update)

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(update)

func update() -> void:
	var dt:float = Engine.get_physics_interpolation_fraction()*Engine.time_scale/Engine.physics_ticks_per_second
	match position_behavior:
		TRACK:
			global_position = get_parent().global_position
		INTERPOLATE:
			global_position = get_parent().global_position + get_parent().linear_velocity * dt
	match rotation_behavior:
		TRACK:
			global_rotation = get_parent().global_rotation
		INTERPOLATE:
			global_rotation = get_parent().global_rotation + get_parent().angular_velocity * dt
	match scale_behavior:
		TRACK, INTERPOLATE:
			global_scale = get_parent().global_scale
