class_name HitNumber
extends Label

var velocity:Vector2
var number:int:
	set(to):
		number = to
		text = str(number)
var lifetime:float = 1

func _process(delta: float) -> void:
	position += velocity * delta
	velocity += (get_viewport().get_camera_2d().velocity - velocity) * delta
	lifetime -= delta
	modulate.a = min(lifetime*4,1)
	if(lifetime<0):
		queue_free()
