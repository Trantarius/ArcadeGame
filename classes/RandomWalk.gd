class_name RandomWalk
extends Resource

## Maximum distance from the offset.
@export var max_distance:float = 256
## Minimum distance form the offset.
@export var min_distance:float = 128
## Minimum distance between two points on the path, excluding shortened steps to stay with [member min_distance] and [member max_distance].
@export var min_step:float = 16
## Maximum distance between two points on the path.
@export var max_step:float = 64
## How quickly the offset moves along the path (on average).
@export var speed:float = 128

## Offsets the "center" position, which [member min_distance] and [member max_distance] are relative to.
var offset:Vector2


var bz_a:Vector2
var bz_b:Vector2
var bz_c:Vector2
var bz_t:float

var position:Vector2
var velocity:Vector2
var acceleration:Vector2

func step_point(from:Vector2)->Vector2:
	
	var t_1:float = acos(min_distance/(from-offset).length())
	var t_2:float = acos(min_distance/max_distance)
	var t_a:float = (from-offset).angle()
	var theta_max:float = t_a + t_1 + t_2
	var theta_min:float = t_a - t_1 - t_2
	theta_min = theta_min if theta_min<theta_max else theta_min-TAU
	
	var toward:Vector2 = Vector2.from_angle(randf_range(theta_min,theta_max))*max_distance + offset
	var next:Vector2 = from + (toward-from).limit_length(sqrt(randf_range(min_step**2,max_step**2)))
	return next

func reset(start:Vector2=Vector2(INF,INF))->void:
	if(is_inf(start.x)):
		start = Vector2.from_angle(randf()*TAU)*sqrt(randf_range(min_distance**2,max_distance**2)) + offset
	
	bz_a = start
	bz_b = (start+step_point(start))/2
	bz_c = (bz_b+step_point(bz_b))/2
	bz_t = 0
	step(0)

func step(delta: float) -> void:
		
	var t_ratio:float = 2*speed/(min_step+max_step)
	bz_t += delta*t_ratio
	
	while(bz_t>1):
		bz_a = bz_c
		bz_b = bz_b + 2*(bz_c-bz_b)
		bz_c = (bz_b+step_point(bz_b))/2
		bz_t -= 1
	
	position = lerp(lerp(bz_a,bz_b,bz_t),lerp(bz_b,bz_c,bz_t),bz_t)
	velocity = 2*lerp(bz_b-bz_a,bz_c-bz_b,bz_t)*t_ratio
	acceleration = 2*((bz_c-bz_b)-(bz_b-bz_a))*t_ratio**2
