class_name RandomWalk
extends Node2D

## Maximum length of the offset
@export var max_distance:float = 256
## Minimum distance between two points on the path
@export var min_step:float = 16
## Maximum distance between two points on the path
@export var max_step:float = 64
## How quickly the offset moves along the path
@export var speed:float = 128
## Bias towards the direction it is already moving
@export var momentum:float = 0

enum {LINEAR=0,CUBIC=1,BEZIER=2}
## Method of interpolation between steps
@export_enum("Linear:0","Cubic:1","Bezier:2") var interpolation:int

@export var draw_line:bool = false:
	set(to):
		if(draw_line!=to):
			draw_line=to
			if(draw_line):
				line=Line2D.new()
				line.width=2
				add_child(line,false,Node.INTERNAL_MODE_FRONT)
			else:
				if(is_instance_valid(line)):
					line.queue_free()
				current_line_length=0
				line_points=[]
@export var line_length:float = 128
var line:Line2D
var current_line_length:float = 0
var line_points:Array[Vector2]=[]

var points:Array[Vector2]
var progress:float

func step_point(from:Vector2)->Vector2:
	var toward:Vector2 = Vector2.from_angle(randf()*TAU)*sqrt(randf())*max_distance
	var dir:Vector2 = (toward-from).normalized()
	if(points.size()>=2):
		dir += (points[-1]-points[-2]).normalized() * momentum
		dir = dir.normalized()
	return from + dir*sqrt(randf_range(min_step*min_step,max_step*max_step))

func _ready()->void:
	reset()

func reset(start:Vector2=Vector2(INF,INF))->void:
	points=[]
	if(draw_line):
		line_points=[]
		current_line_length=0
		line.points=line_points
	if(is_inf(start.x)):
		start = Vector2.from_angle(randf()*TAU)*sqrt(randf())*max_distance
	points.push_back(step_point(start))
	points.push_back(start)
	points.push_back(step_point(start))
	points.push_back(step_point(points.back()))
	progress = 0
	position=points[1]

func _physics_process(delta: float) -> void:
	progress += delta*speed/(points[2]-points[1]).length()
	while(progress>1):
		points.push_back(step_point(points.back()))
		points.pop_front()
		progress-=1
	
	match(interpolation):
		LINEAR:
			position = points[1].lerp(points[2],progress)
		CUBIC:
			position = points[1].cubic_interpolate(points[2],points[0],points[3],progress)
		BEZIER:
			position = lerp(lerp(points[0],points[1],(progress+1)/2),lerp(points[1],points[2],progress/2),progress)
		
	if(draw_line):
		if(!line_points.is_empty()):
			current_line_length += (position-line_points.back()).length()
			while(line_points.size()>=2 && current_line_length>=line_length):
				current_line_length -= (line_points[1]-line_points[0]).length()
				line_points.pop_front()
		line_points.push_back(position)
		line.points=line_points
		line.position=-position

