class_name Interpolator
extends Node2D

enum{IGNORE=0,TRACK=1,INTERPOLATE=2}
@export_enum('Ignore:0','Track:1','Interpolate:2') var position_behavior:int = INTERPOLATE
@export_enum('Ignore:0','Track:1','Interpolate:2') var rotation_behavior:int = INTERPOLATE
@export_enum('Ignore:0','Track:1') var scale_behavior:int = TRACK
@export_enum('Ignore:0','Track:1') var modulate_behavior:int = TRACK

## If non-null, the parent's linear velocity is ignored and this is used instead. Must be either null or a Vector2.
var linear_velocity_override:Variant = null
## If non-null, the parent's angular velocity is ignored and this is used instead. Must be either null or a float.
var angular_velocity_override:Variant = null

func _ready()->void:
	top_level = true
	global_transform = get_parent().global_transform

func _process(_delta:float) -> void:
	var dt:float = Engine.get_physics_interpolation_fraction()*Engine.time_scale/Engine.physics_ticks_per_second
	match position_behavior:
		TRACK:
			global_position = get_parent().global_position
		INTERPOLATE:
			global_position = get_parent().global_position + (
				linear_velocity_override if linear_velocity_override is Vector2 else get_parent().linear_velocity) * dt
	match rotation_behavior:
		TRACK:
			global_rotation = get_parent().global_rotation
		INTERPOLATE:
			global_rotation = get_parent().global_rotation + (
				angular_velocity_override if angular_velocity_override is float else get_parent().angular_velocity) * dt
	match scale_behavior:
		TRACK:
			global_scale = get_parent().global_scale
	match modulate_behavior:
		TRACK:
			modulate = get_parent().modulate
