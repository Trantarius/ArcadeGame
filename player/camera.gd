extends Camera2D

var velocity:Vector2
## enables moving under its own velocity
var is_free:bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	$AmbientParticles.process_material.set_shader_parameter('width',get_viewport().size.x)
	$AmbientParticles.process_material.set_shader_parameter('height',get_viewport().size.y)
	if(is_free):
		position += velocity*delta
