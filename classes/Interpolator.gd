class_name Interpolator
extends Node2D

@export var target:Node2D
@export var offset_target:Node2D
@export var offset:Transform2D = Transform2D.IDENTITY

enum{IGNORE=0,TRACK=1,INTERPOLATE=2}
@export_enum('Ignore:0','Track:1','Interpolate:2') var position_behavior:int = INTERPOLATE
@export_enum('Ignore:0','Track:1','Interpolate:2') var rotation_behavior:int = INTERPOLATE
@export_enum('Ignore:0','Track:1') var scale_behavior:int = TRACK
@export_enum('Ignore:0','Track:1') var modulate_behavior:int = TRACK

## If non-null, the target's linear velocity is ignored and this is used instead. Must be either null or a Vector2.
var linear_velocity_override:Variant = null
## If non-null, the target's angular velocity is ignored and this is used instead. Must be either null or a float.
var angular_velocity_override:Variant = null

func _ready()->void:
	if(!is_instance_valid(target)):
		target = get_parent()
	top_level = true
	global_transform = target.global_transform

func _process(_delta:float) -> void:
	var dt:float = Engine.get_physics_interpolation_fraction()*Engine.time_scale/Engine.physics_ticks_per_second
	if(is_instance_valid(offset_target)):
		offset = offset_target.transform
	
	match position_behavior:
		TRACK:
			global_position = (target.global_transform * offset).origin
			
		INTERPOLATE:
			var localpos:Vector2 = (target.global_transform * offset).origin
			var velocity:Vector2
			if(linear_velocity_override is Vector2):
				velocity = linear_velocity_override
			elif('linear_velocity' in target):
				if('angular_velocity' in target):
					if('center_of_mass' in target):
						velocity = target.linear_velocity + target.angular_velocity * (localpos-(target.global_position+target.center_of_mass)).orthogonal()
					else:
						velocity = target.linear_velocity + target.angular_velocity * (localpos-target.global_position).orthogonal()
				else:
					velocity = target.linear_velocity
			else:
				velocity = Vector2.ZERO
				
			global_position = localpos + velocity * dt
			
	match rotation_behavior:
		TRACK:
			global_rotation = (target.global_transform * offset).get_rotation()
		INTERPOLATE:
			global_rotation = (target.global_transform * offset).get_rotation() + (
				angular_velocity_override if angular_velocity_override is float else (
				target.angular_velocity if 'angular_velocity' in target else 0)) * dt
				
	match scale_behavior:
		TRACK:
			global_scale = (target.global_transform * offset).get_scale()
	match modulate_behavior:
		TRACK:
			modulate = target.modulate
