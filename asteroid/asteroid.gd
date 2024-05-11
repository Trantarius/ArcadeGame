@tool
class_name Asteroid
extends RigidBody2D

@export var noise:FastNoiseLite:
	set(to):
		if(is_instance_valid(noise)):
			noise.changed.disconnect(generate)
		noise=to
		noise.changed.connect(generate)
		generate()

## Amount of deformation on the asteroid's shape.
@export_range(0,1) var noise_strength:float:
	set(to):
		noise_strength=to
		generate()

## Size of the asteroid.
@export var radius:float=256:
	set(to):
		radius=to
		generate()

## Maximum scaling of the shape along a single axis.
@export_range(0,1) var stretch_limit:float=0.3:
	set(to):
		stretch_limit=to
		generate()

## Minimum distance between adjacent points on the polygon.
@export var resolution:float=16:
	set(to):
		if(to>8):
			resolution=to
			generate()

## A parameter to control the strength of the polygon complexity reduction.
@export_range(0,0.2) var curvature_limit:float=0.01:
	set(to):
		curvature_limit=to
		generate()

static func change_poly_resolution(poly:PackedVector2Array,res:float)->PackedVector2Array:
	var retpoly:PackedVector2Array = []
	var dist:float = 0
	for idx:int in range(poly.size()):
		var seglen:float = (poly[(idx+1)%poly.size()]-poly[idx]).length()
		dist += seglen
		while(dist>res):
			dist-=res
			retpoly.push_back(lerp(poly[idx], poly[(idx+1)%poly.size()], (seglen-dist)/seglen))
	if(dist>res/2):
		retpoly.push_back(poly[0])
	return retpoly

static func calc_poly_normals(poly:PackedVector2Array)->PackedVector2Array:
	var normals:PackedVector2Array=[]
	for n:int in range(poly.size()):
		var dir:Vector2 = ((poly[(n+1)%poly.size()]-poly[n])+(poly[n]-poly[n-1]))
		normals.push_back(dir.normalized().orthogonal())
	return normals

static func optimize_curvature(poly:PackedVector2Array, limit:float )->PackedVector2Array:
	var retpoly:PackedVector2Array=[]
	var last_dir:Vector2 = (poly[0]-poly[-1]).normalized()
	for idx:int in range(poly.size()):
		var dir:Vector2 = (poly[(idx+1)%poly.size()]-poly[idx]).normalized()
		if(dir.dot(last_dir)<(1-limit)):
			retpoly.push_back(poly[idx])
			last_dir = dir
	return retpoly

static func is_polygon_self_intersecting(poly:PackedVector2Array)->bool:
	for n:int in range(poly.size()):
		for i:int in range(poly.size()):
			if(i==n||i==n-1||i==n+1||(i==0&&n==poly.size()-1)||(i==poly.size()-1&&n==0)):
				continue
			if(Geometry2D.segment_intersects_segment(poly[n-1],poly[n],poly[i-1],poly[i])):
				return true
	return false

## Generates the polygon for the asteroid in a worker thread. 
static func create_asteroid_polygon(_noise:FastNoiseLite, _noise_strength:float, _radius:float,
	_stretch_limit:float, _resolution:float, _curvature_limit:float)->PackedVector2Array:
	
	_noise=_noise.duplicate()
	
	# a dummy object to hold a 'done' signal
	var done_object:Object = Object.new()
	done_object.add_user_signal("done",[{'name':'poly','type':TYPE_PACKED_VECTOR2_ARRAY}])
	var done_signal:Signal = Signal(done_object, "done")
	
	var thread_func:Callable=func()->void:
		var poly:PackedVector2Array = []
		var rand:RandomNumberGenerator = RandomNumberGenerator.new()
		rand.seed = _noise.seed
		var stretch:float = rand.randf()*_stretch_limit
		var rot:float = TAU*rand.randf()
		_noise.set_block_signals(true)
		_noise.frequency = 4.0/_radius
		_noise.set_block_signals(false)
		
		for s:int in range(8):
			var subshape:PackedVector2Array=[]
			var bias:Vector2 = Vector2(
				rand.randf_range(-1,1)*_radius/2,
				rand.randf_range(-1,1)*_radius/2)
			bias *= Vector2(1+stretch,1-stretch)
			bias = bias.rotated(rot)
			for p:int in range(32):
				var point:Vector2 = Vector2.from_angle(rand.randf()*TAU)*rand.randf()*_radius/2.5
				subshape.push_back(point+bias)
			subshape = Geometry2D.convex_hull(subshape)
			poly = Geometry2D.merge_polygons(poly,subshape)[0]
		poly = change_poly_resolution(poly,_radius/4)
		
		var normals:PackedVector2Array = calc_poly_normals(poly)
		for n:int in range(poly.size()):
			var nval:float = _noise.get_noise_2dv(poly[n])
			poly[n] += normals[n] * nval * _noise_strength * _radius
		
		poly = change_poly_resolution(poly,_resolution)
		
		normals = calc_poly_normals(poly)
		for n:int in range(poly.size()):
			var nval:float = _noise.get_noise_2dv(poly[n])
			poly[n] += normals[n] * nval * _noise_strength * _radius
		
		poly = change_poly_resolution(poly,_resolution)
		poly = optimize_curvature(poly,_curvature_limit)
		if(is_polygon_self_intersecting(poly)):
			poly=[]
		done_object.call_deferred("emit_signal","done",poly)
	
	WorkerThreadPool.add_task(thread_func)
	return await done_signal

# helps to de-duplicate generate calls that may overlap due to multi-threading/coroutines
var _generate_queued:bool = false
var _generate_running:bool = false

func _enter_tree()->void:
	if(_generate_queued && !_generate_running):
		_generate_queued=false
		generate()

func generate()->void:
	
	if(_generate_running || !is_inside_tree()):
		_generate_queued=true
		return
	
	# with the right parameters, a failed attempt is pretty rare, so just trying again with a new seed will probably fix it
	const max_attempts:int=3
	
	var poly:PackedVector2Array = []
	for a:int in range(max_attempts):
		
		_generate_running=true
		poly = await Asteroid.create_asteroid_polygon(noise,noise_strength,radius,stretch_limit,resolution,curvature_limit)
		_generate_running=false
		if(_generate_queued):
			_generate_queued=false
			generate()
			return
		
		if(poly.is_empty()):
			noise.set_block_signals(true)
			noise.seed += 1
			noise.set_block_signals(false)
		else:
			break
	
	if(poly.is_empty()):
		push_error("Failed to create asteroid polygon after ",max_attempts," attempts")
		return
	
	$Interpolator/Polygon2D.polygon = poly
	$CollisionPolygon2D.polygon = poly
