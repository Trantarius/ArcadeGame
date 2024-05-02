extends Camera2D

var velocity:Vector2
## enables moving under its own velocity
var is_free:bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(is_free):
		position += velocity*delta
