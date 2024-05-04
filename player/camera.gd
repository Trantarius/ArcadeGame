extends Camera2D

var velocity:Vector2

## Enables moving under its own velocity
var is_free:bool = false

## Number of ambient particles per million pixels (ie, in a 1000x1000 area)
@export var ambient_particle_density:float = 100

func _ready()->void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed()->void:
	var vp:Viewport = get_viewport()
	$AmbientParticles.process_material.set_shader_parameter('width',vp.size.x)
	$AmbientParticles.process_material.set_shader_parameter('height',vp.size.y)
	$AmbientParticles.amount = ambient_particle_density * vp.size.x*vp.size.y / 1_000_000

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if(is_free):
		position += velocity*delta
