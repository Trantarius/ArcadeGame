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

@export var bezier_level:int = 0

## Offsets the "center" position, which [member min_distance] and [member max_distance] are relative to.
var offset:Vector2

#var p_a:Vector2
#var p_b:Vector2
#var p_c:Vector2
#var p_d:Vector2
#var p_e:Vector2

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
	
	
	#p_a = start
	#p_b = step_point(p_a)
	#p_c = step_point(p_b)
	#p_d = step_point(p_c)
	#p_e = step_point(p_d)
	
	bz_a = start
	bz_b = (start+step_point(start))/2
	bz_c = (bz_b+step_point(bz_b))/2
	bz_t = 0
	
	#prev_prev_point = step_point(start, Vector2.ZERO)
	#prev_point = start
	#next_point = step_point(prev_point, (prev_point-prev_prev_point))
	#next_next_point = step_point(next_point, (next_point-prev_point))
	
	#points.push_back(step_point(start))
	#points.push_back(start)
	#points.push_back(step_point(start))
	#points.push_back(step_point(points.back()))
	#progress = 0
	step(0)

func step(delta: float) -> void:
	#progress += delta*speed/(points[2]-points[1]).length()
	#while(progress>1):
		#points.push_back(step_point(points.back()))
		#points.pop_front()
		#progress-=1
		
	var t_ratio:float = 2*speed/(min_step+max_step)
	bz_t += delta*t_ratio
	
	while(bz_t>1):
		#p_a=p_c
		#p_b=p_d
		#p_c=p_e
		#p_d=step_point(p_e)
		#p_e=step_point(p_d)
		bz_a = bz_c
		bz_b = bz_b + 2*(bz_c-bz_b)
		bz_c = (bz_b+step_point(bz_b))/2
		bz_t -= 1
	
	
	#var bz:PackedVector2Array = [((p_a+p_b)/2+(p_b+p_c)/2)/2, (p_b+p_c)/2, p_c, (p_c+p_d)/2, ((p_d+p_e)/2+(p_c+p_d)/2)/2]
	#
	#var bz_p:PackedVector2Array = bz.duplicate()
	#for n:int in range(4):
		#for i:int in range(4-n):
			#bz_p[i]=lerp(bz_p[i],bz_p[i+1],bz_t)
	#position = bz_p[0]
	#
	#var bz_v:PackedVector2Array = bz.duplicate()
	#for n:int in range(4):
		#bz_v[n]=bz_v[n+1]-bz_v[n]
	#for n:int in range(3):
		#for i:int in range(3-n):
			#bz_v[i]=lerp(bz_v[i],bz_v[i+1],bz_t)
	#velocity = bz_v[0] * t_ratio * 4
	#
	#var bz_a:PackedVector2Array = bz.duplicate()
	#for n:int in range(4):
		#bz_a[n]=bz_a[n+1]-bz_a[n]
	#for n:int in range(3):
		#bz_a[n]=bz_a[n+1]-bz_a[n]
	#acceleration = lerp(lerp(bz_a[0],bz_a[1],bz_t),lerp(bz_a[1],bz_a[2],bz_t),bz_t) * t_ratio**2 * 12
	
	position = lerp(lerp(bz_a,bz_b,bz_t),lerp(bz_b,bz_c,bz_t),bz_t)
	velocity = 2*lerp(bz_b-bz_a,bz_c-bz_b,bz_t)*t_ratio
	acceleration = 2*((bz_c-bz_b)-(bz_b-bz_a))*t_ratio**2
	
	#var bza:Vector2 = (prev_prev_point+prev_point)/2 if progress<0.5 else (prev_point+next_point)/2
	#var bzb:Vector2 = prev_point if progress<0.5 else next_point
	#var bzc:Vector2 = (prev_point+next_point)/2 if progress<0.5 else (next_point+next_next_point)/2
	#var bzt:float = progress+0.5 if progress<0.5 else progress-0.5
	#
	#var prog_ratio:float = speed/(lerp((bzb-bza),(bzc-bzb),progress).length()*2)
	#progress += delta*prog_ratio
	#while(progress>1):
		#prev_prev_point = prev_point
		#prev_point = next_point
		#next_point = next_next_point
		#next_next_point = step_point(next_point, (next_point-prev_point))
		#progress-=1
	#
	#
	#bza = (prev_prev_point+prev_point)/2 if progress<0.5 else (prev_point+next_point)/2
	#bzb = prev_point if progress<0.5 else next_point
	#bzc = (prev_point+next_point)/2 if progress<0.5 else (next_point+next_next_point)/2
	#bzt = progress+0.5 if progress<0.5 else progress-0.5
	
	# quadratic bezier curve
	#position = (bza-2*bzb+bzc)*bzt**2 + 2*(bzb-bza)*bzt + bza
	#velocity = (2*(bza-2*bzb+bzc)*bzt + 2*(bzb-bza)) * prog_ratio
	#acceleration = 2*(bza-2*bzb+bzc) * (prog_ratio)**2
	
	#position = lerp(lerp(points[0],points[1],(progress+1)/2),lerp(points[1],points[2],progress/2),progress)
		
