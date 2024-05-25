extends Camera2D

## Number of ambient particles per million pixels (ie, in a 1000x1000 area)
@export var ambient_particle_density:float = 100

## Enables moving under its own velocity
var is_free:bool = false
var velocity:Vector2

var _last_pos:Vector2

func _ready()->void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	top_level = true

func _on_viewport_size_changed()->void:
	var vp:Viewport = get_viewport()
	$AmbientParticles.process_material.set_shader_parameter('width',vp.size.x)
	$AmbientParticles.process_material.set_shader_parameter('height',vp.size.y)
	$AmbientParticles.amount = ambient_particle_density * vp.size.x*vp.size.y / 1_000_000

func _process(delta: float) -> void:
	if(is_free):
		position += velocity * delta
	else:
		velocity = (global_position-_last_pos)/delta
		_last_pos = global_position
		
		var dt:float = (Engine.get_physics_interpolation_fraction()*Engine.time_scale)/Engine.physics_ticks_per_second
		var targpos:Vector2 = get_parent().position + get_parent().linear_velocity * dt
		var disp:Vector2 = (targpos-position).limit_length(get_parent().max_linear_speed*delta)
		global_position += disp
		
