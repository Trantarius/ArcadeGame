class_name Asteroid
extends RigidBody2D

@export var noise:FastNoiseLite

## Amount of deformation on the asteroid's shape.
@export_range(0,1) var noise_strength:float

## Approximate size of the asteroid.
@export var radius:float=256

## Maximum scaling of the shape along a single axis.
@export_range(0,1) var stretch_limit:float=0.3

## Minimum distance between adjacent points on the polygon.
@export var resolution:float=16

## A parameter to control the strength of the polygon complexity reduction.
@export_range(0,0.2) var curvature_limit:float=0.01

@export_flags_avoidance var avoidance_layer:int

var polygon:PackedVector2Array
var polygon_low:PackedVector2Array

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
	_stretch_limit:float, _resolution:float, _curvature_limit:float)->Dictionary:
	
	_noise=_noise.duplicate()
	
	# a dummy object to hold a 'done' signal
	var done_object:Object = Object.new()
	done_object.add_user_signal("done",[{'name':'ret','type':TYPE_DICTIONARY}])
	var done_signal:Signal = Signal(done_object, "done")
	
	var thread_func:Callable=func()->void:
		var ret:Dictionary={&'poly':PackedVector2Array(), &'poly_low':PackedVector2Array(), &'chunks':Array(), &'time':Time.get_ticks_usec()}
		var rand:RandomNumberGenerator = RandomNumberGenerator.new()
		rand.seed = _noise.seed
		var stretch:float = rand.randf()*_stretch_limit
		var rot:float = TAU*rand.randf()
		_noise.set_block_signals(true)
		_noise.frequency = 1.0/_radius
		_noise.set_block_signals(false)
		
		var chunk_count:int = rand.randi()%2 + rand.randi()%2 + rand.randi()%2 + rand.randi()%2 + 2
		var max_chunk_radius:float = _radius*0.75
		var min_chunk_radius:float = _radius*0.25
		var chunk_verts:int = 16
		var chunk_min_penetration_ratio:float = 1-cos(TAU/chunk_verts/2)
		var chunk_max_penetration_ratio:float = 1
		
		while(ret.chunks.size()<chunk_count):
			var cpos:Vector2 = Vector2(rand.randfn(0,_radius/2),rand.randfn(0,_radius/2))
			cpos = (cpos*Vector2(1+stretch,1-stretch)).rotated(rot)
			var crad:float = rand.randf_range(min_chunk_radius,max_chunk_radius)
			if(ret.chunks.is_empty()):
				cpos=Vector2.ZERO
				ret.chunks.push_back({&'position':cpos,&'radius':crad})
			else:
				var keep:bool = false
				for other:Dictionary in ret.chunks:
					var max_pen:float = min(crad,other.radius)*chunk_max_penetration_ratio
					var min_pen:float = chunk_min_penetration_ratio*(crad+other.radius)
					var pen:float = crad+other.radius - (cpos-other.position).length()
					# must not exceed max_pen with any other chunk
					if(pen>max_pen):
						keep=false
						break
					# must exceed min_pen with exactly one other chunk
					if(pen>min_pen):
						if(keep):
							keep=false
							break
						else:
							keep=true
				if(keep):
					ret.chunks.push_back({&'position':cpos,&'radius':crad})
		
		var avg_cpos:Vector2
		var tot_weight:float
		for chunk:Dictionary in ret.chunks:
			avg_cpos += chunk.position * chunk.radius
			tot_weight += chunk.radius
		avg_cpos /= tot_weight
		for chunk:Dictionary in ret.chunks:
			chunk.position -= avg_cpos
		
		var extent:float = 0
		for chunk:Dictionary in ret.chunks:
			extent=max(chunk.position.length()+chunk.radius,extent)
		var rescale:float = _radius/extent
		for chunk:Dictionary in ret.chunks:
			chunk.position *= rescale
			chunk.radius *= rescale
		
		for chunk:Dictionary in ret.chunks:
			var cpoly:PackedVector2Array
			for v:int in range(chunk_verts):
				cpoly.push_back(chunk.position + chunk.radius * Vector2.from_angle(v*TAU/chunk_verts))
			ret.poly_low = Geometry2D.merge_polygons(ret.poly_low, cpoly)[0]
		ret.poly_low = change_poly_resolution(ret.poly_low, _radius/4)
		
		var normals:PackedVector2Array = calc_poly_normals(ret.poly_low)
		for n:int in range(ret.poly_low.size()):
			var nval:float = _noise.get_noise_2dv(ret.poly_low[n])
			ret.poly_low[n] += normals[n] * nval * _noise_strength * _radius
		
		ret.poly = change_poly_resolution(ret.poly_low,_resolution)
		
		normals = calc_poly_normals(ret.poly)
		for n:int in range(ret.poly.size()):
			var nval:float = _noise.get_noise_2dv(ret.poly[n])
			ret.poly[n] += normals[n] * nval * _noise_strength * _radius
		
		ret.poly = change_poly_resolution(ret.poly,_resolution)
		ret.poly = optimize_curvature(ret.poly,_curvature_limit)
		if(is_polygon_self_intersecting(ret.poly)):
			ret.poly.clear()
		ret.time = Time.get_ticks_usec()-ret.time
		done_object.call_deferred("emit_signal","done",ret)
	
	WorkerThreadPool.add_task(thread_func)
	return await done_signal

# helps to de-duplicate generate calls that may overlap due to multi-threading/coroutines
var _generate_running:bool = false

func _ready()->void:
	generate()

func generate()->void:
	
	while(_generate_running):
		await get_tree().physics_frame
	_generate_running=true
	
	# with the right parameters, a failed attempt is pretty rare, so just trying again with a new seed will probably fix it
	const max_attempts:int=5
	
	var result:Dictionary
	for a:int in range(max_attempts):
		
		_generate_running=true
		result = await Asteroid.create_asteroid_polygon(
			noise,noise_strength,radius,stretch_limit,resolution,curvature_limit)
		_generate_running=false
		
		if(result.poly.is_empty()):
			noise.set_block_signals(true)
			noise.seed += 1
			noise.set_block_signals(false)
		else:
			break
	
	if(result.poly.is_empty()):
		push_error("Failed to create asteroid polygon after ",max_attempts," attempts")
	
	else:
		$Interpolator/Polygon2D.polygon = result.poly
		$CollisionPolygon2D.polygon = result.poly
		polygon = result.poly
		polygon_low = result.poly_low
		
		for child:Node in get_children(true):
			if(child is NavigationObstacle2D):
				child.queue_free()
		for chunk:Dictionary in result.chunks:
			var obs:NavigationObstacle2D = NavigationObstacle2D.new()
			obs.avoidance_enabled=true
			obs.avoidance_layers = avoidance_layer
			obs.radius = chunk.radius + noise_strength*radius
			obs.position = chunk.position
			obs.z_index=1
			add_child(obs,false,Node.INTERNAL_MODE_BACK)
	
	_generate_running=false

func _physics_process(_delta: float) -> void:
	for child:Node in get_children():
		if(child is NavigationObstacle2D):
			child.velocity = linear_velocity + (child.global_position - global_transform * center_of_mass).orthogonal()*angular_velocity
