extends Polygon2D

var linear_velocity:Vector2
var angular_velocity:float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += linear_velocity*delta
	rotation += angular_velocity*delta
