@tool
class_name ArcDetector
extends Area2D

@export var max_range:float = 500:
	set(to):
		max_range = to
		make_detector_shape()

@export_range(0.01,PI-0.01) var max_angle:float = 1:
	set(to):
		max_angle = to
		make_detector_shape()

@export_range(0.01, PI/2) var step_size:float = 0.25:
	set(to):
		step_size = to
		make_detector_shape()

var shapenode:CollisionPolygon2D

func _ready():
	make_detector_shape()

func make_detector_shape()->void:
	if(!is_instance_valid(shapenode)):
		shapenode = CollisionPolygon2D.new()
		add_child(shapenode, false, Node.INTERNAL_MODE_BACK)
	
	var points:PackedVector2Array = [Vector2.ZERO]
	var stepcount:int = max(ceili(2*max_angle/step_size),1)
	var thetastep:float = 2*max_angle / stepcount
	points.resize(stepcount+2)
	for n:int in range(1,stepcount+2):
		points[n] = Vector2.from_angle((n-1)*thetastep - max_angle) * max_range
	shapenode.polygon = points
