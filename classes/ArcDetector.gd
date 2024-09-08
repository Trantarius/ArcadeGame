## This class handles arc-shaped detection of physics bodies, and can optionally use raycasts
## to ensure those bodies are "visible" to the detector.
@tool
class_name ArcDetector
extends Area2D

## Maximum distance at which to detect something. 
@export var max_range:float = 500:
	set(to):
		max_range = to
		_make_detector_shape()

## Maximum angle from center at which something can be detected.
@export_range(0.01,PI-0.01) var max_angle:float = 1:
	set(to):
		max_angle = to
		_make_detector_shape()

## Determines the precision of the detection shape. This is the approximate angle between
## each vertex on the outer edge of the shape.
@export_range(0.01, PI/2) var step_size:float = 0.25:
	set(to):
		step_size = to
		_make_detector_shape()

## Maximum number of detected bodies that are reported. 
@export var max_detected_count:int = 1

## Enables the use of raycasting to ensure the detected body is "visible".
@export var require_raycast:bool = false
## Minimum angle between raycast attempts. Effectively places an upper limit on how long the 
## detector will try to find a successful raycast.
@export var min_raycast_separation:float = 0.05
## Ensures a minimum angular difference between a body that the raycast is "going around" and the ray itself.
@export var raycast_hint_margin:float = 0.05
## Physics layers that can stop the raycast. This is in addition to [member collision_mask].
@export_flags_2d_physics var raycast_mask:int

## Enables drawing the detection area, and the attempted raycasts. Also causes the detector to be updated
## every physics frame.
@export var debug_draw:bool = false:
	set(to):
		debug_draw=to
		queue_redraw()

## The detected nodes in the form of {node:raycast_result}. If [member require_raycast] is false, the result is always {}.
var detected:Dictionary
## Number of raycasts performed in the last update.
var raycasts_used:int

# form of {collider:[shape_idx...]}
var _overlapping:Dictionary
var _shapenode:CollisionPolygon2D
var _is_drawing:bool = false

func _ready():
	area_shape_entered.connect(_on_collider_shape_entered)
	body_shape_entered.connect(_on_collider_shape_entered)
	area_shape_exited.connect(_on_collider_shape_exited)
	body_shape_exited.connect(_on_collider_shape_exited)
	_make_detector_shape()

func _physics_process(_delta: float) -> void:
	if(!Engine.is_editor_hint() && debug_draw):
		queue_redraw()

func _on_collider_shape_entered(collider_rid:RID, collider:CollisionObject2D, collider_shape_index:int, local_shape_index:int)->void:
	if(!_overlapping.has(collider)):
		_overlapping[collider] = []
	if(!_overlapping[collider].has(collider_shape_index)):
		_overlapping[collider].push_back(collider_shape_index)

func _on_collider_shape_exited(collider_rid:RID, collider:CollisionObject2D, collider_shape_index:int, local_shape_index:int)->void:
	if(_overlapping.has(collider)):
		_overlapping[collider].erase(collider_shape_index)
		if(_overlapping[collider].is_empty()):
			_overlapping.erase(collider)

## Updates the [member detected] array with the bodies intersecting the area.
## If [member require_raycast] is enabled, raycasts will be used to verify the detected bodies are reachable.
func update_detected()->void:
	raycasts_used = 0
	var raycast_record:Array[Dictionary]=[]
	var d:int = 0
	while(d<detected.size()):
		if(!is_instance_valid(detected.keys()[d])):
			detected.erase(detected.keys()[d])
			continue
		var collider:CollisionObject2D = detected.keys()[d]
		if(!_overlapping.has(collider)):
			detected.erase(collider)
		elif(require_raycast):
			var result:Dictionary = _raycast_test(collider,raycast_record)
			if(result.is_empty()):
				detected.erase(collider)
			else:
				detected[collider]=result
				d+=1
		else:
			d+=1
	
	for newobject:CollisionObject2D in _overlapping.keys():
		if(detected.size()>=max_detected_count):
			break
		if(detected.has(newobject)):
			continue
		if(require_raycast):
			var result:Dictionary = _raycast_test(newobject,raycast_record)
			if(!result.is_empty()):
				detected[newobject]=result
		else:
			detected[newobject]={}
	
	if(_is_drawing):
		for ray:Dictionary in raycast_record:
			draw_line(Vector2.ZERO, Vector2.from_angle(ray.angle-global_rotation)*max_range if ray.result.is_empty() else 
			global_transform.affine_inverse() * ray.result.front().position, Color(0,1,0,0.5) if ray.success else Color(1,0,0,0.5))
		for det:CollisionObject2D in detected:
			if(require_raycast):
				_draw_target(detected[det].position,Color(1,0,1),8)
			else:
				_draw_target(det.global_position,Color(1,0,1),8)

# used for sorting rays by angle
func _cmp_rays(a:Dictionary, b:Dictionary)->bool:
	return angle_difference(0,a.angle)<angle_difference(0,b.angle)

# handles all raycasts for one object
func _raycast_test(object:CollisionObject2D,raycast_record:Array[Dictionary])->Dictionary:
	var todo:Array[float]
	var hints:Array[float]
	
	if(!_overlapping.has(object)):
		return {}
	var local_tf:Transform2D = object.shape_owner_get_transform(object.shape_find_owner(_overlapping[object][0]))
	var shape_res:Shape2D = Util.collider_get_shape2d(object, _overlapping[object][0])
	var shape_bounds_center:Vector2 = (shape_res.get_rect().position + shape_res.get_rect().end)/2
	var pos:Vector2 = object.global_transform * local_tf * shape_bounds_center
	var theta:float = Util.angle_clamp((pos-global_position).angle(), -max_angle+global_rotation, max_angle+global_rotation)
	#var dict:Dictionary = _attempt_raycast(object, angle, hints, attempts)
	todo = [theta]
	
	for n:int in range(3):
		for angle:float in todo:
			var dict:Dictionary = _attempt_raycast(object, angle, hints, raycast_record)
			if(!dict.is_empty()):
				if(dict.shape!=_overlapping[object][0]):
					var hit_n:int = _overlapping[object].find(dict.shape)
					if(hit_n>=0):
						_overlapping[object].remove_at(hit_n)
					_overlapping[object].push_front(dict.shape)
				if(_is_drawing):
					local_tf = object.shape_owner_get_transform(object.shape_find_owner(dict.shape))
					shape_res = Util.collider_get_shape2d(object, dict.shape)
					shape_bounds_center = (shape_res.get_rect().position + shape_res.get_rect().end)/2
					pos = object.global_transform * local_tf * shape_bounds_center
					_draw_target(pos, Color(1,1,0), 16)
				return dict
		todo = hints
		hints = []
	return {}

# performs a single raycast for an object, and gets the necessary hints if it fails
func _attempt_raycast(object:CollisionObject2D, angle:float, hints:Array[float], raycast_record:Array)->Dictionary:
	
	var result:Array[Dictionary]
	var recn:int = raycast_record.bsearch_custom({'angle':angle},_cmp_rays)
	if(recn<raycast_record.size() && abs(angle_difference(raycast_record[recn].angle, angle))<min_raycast_separation):
		result = raycast_record[recn].result
	elif(raycast_record.size()>1 && abs(angle_difference(raycast_record[recn-1].angle,angle))<min_raycast_separation):
		result = raycast_record[recn-1].result
		recn-=1
	else:
		result = Util.raycast(global_position, global_position + Vector2.from_angle(angle)*max_range, raycast_mask|collision_mask)
		raycast_record.insert(recn,{'angle':angle,'result':result,'success':false})
		raycasts_used += result.size()+1
	
	var success:bool = false
	var ret:Dictionary={}
	for hit:Dictionary in result:
		if(hit.collider==object):
			success=true
			ret = hit
			ret['angle']=angle
			break
	if(!success && !result.is_empty()):
		_get_hint_angles_from_raycast(result,hints)
	if(success):
		raycast_record[recn]['success'] = true
	return ret

# when a raycast fails, try to go around whatever was hit by turning to the edge of the bounding box
# of the hit shape, and continuing in that direction for another raycast_hint_margin radians
func _get_hint_angles_from_raycast(rayresult:Array[Dictionary], hints:Array[float])->void:
	var rayangle:float = (rayresult.front().position-global_position).angle()
	for hit:Dictionary in rayresult:
		var shape:Shape2D = Util.collider_get_shape2d(hit.collider, hit.shape)
		var bounds:Rect2 = shape.get_rect()
		var points:PackedVector2Array = [bounds.position, bounds.end, 
			Vector2(bounds.position.x,bounds.end.y), Vector2(bounds.end.x,bounds.position.y)]
		var tform:Transform2D = hit.collider.global_transform * hit.collider.shape_owner_get_transform(hit.collider.shape_find_owner(hit.shape))
		points = tform * points
		var angles:Array[float]
		for point:Vector2 in points:
			var a:float = angle_difference(rayangle,(point-global_position).angle())
			a += sign(a)*raycast_hint_margin
			angles.push_back(a)
		hints.push_back(Util.angle_clamp(angles.min()+rayangle, -max_angle+global_rotation, max_angle+global_rotation))
		hints.push_back(Util.angle_clamp(angles.max()+rayangle, -max_angle+global_rotation, max_angle+global_rotation))

# generates the shape for the detector, and applies it to the area
func _make_detector_shape()->void:
	if(!is_instance_valid(_shapenode)):
		_shapenode = CollisionPolygon2D.new()
		add_child(_shapenode, false, Node.INTERNAL_MODE_BACK)
	
	var points:PackedVector2Array = [Vector2.ZERO]
	var stepcount:int = max(ceili(2*max_angle/step_size),1)
	var thetastep:float = 2*max_angle / stepcount
	points.resize(stepcount+2)
	for n:int in range(1,stepcount+2):
		points[n] = Vector2.from_angle((n-1)*thetastep - max_angle) * max_range
	_shapenode.polygon = points

func _draw():
	if(debug_draw && !Engine.is_editor_hint()):
		_is_drawing=true
		draw_colored_polygon(_shapenode.polygon,Color(0.25,0.25,1,0.5))
		update_detected()
		_is_drawing=false

func _draw_target(pos:Vector2, color:Color, size:float):
	draw_arc(global_transform.affine_inverse() * pos, size, 0, TAU, 16, color)
	draw_line(global_transform.affine_inverse() * (pos+Vector2(size,size)), global_transform.affine_inverse() * (pos-Vector2(size,size)), color)
	draw_line(global_transform.affine_inverse() * (pos+Vector2(-size,size)), global_transform.affine_inverse() * (pos-Vector2(-size,size)), color)
