@tool
class_name Asteroid
extends RigidBody2D

@export var noise:FastNoiseLite:
	set(to):
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


static func change_poly_resolution(poly:PackedVector2Array,resolution:float)->PackedVector2Array:
	var retpoly:PackedVector2Array = []
	var dist:float = 0
	for idx in range(poly.size()):
		var seglen:float = (poly[(idx+1)%poly.size()]-poly[idx]).length()
		dist += seglen
		while(dist>resolution):
			dist-=resolution
			retpoly.push_back(lerp(poly[idx], poly[(idx+1)%poly.size()], (seglen-dist)/seglen))
	if(dist>resolution/2):
		retpoly.push_back(poly[0])
	return retpoly

static func calc_poly_normals(poly:PackedVector2Array)->PackedVector2Array:
	var normals:PackedVector2Array=[]
	for n in range(poly.size()):
		var dir:Vector2 = ((poly[(n+1)%poly.size()]-poly[n])+(poly[n]-poly[n-1]))
		normals.push_back(dir.normalized().orthogonal())
	return normals

static func optimize_curvature(poly:PackedVector2Array, limit:float )->PackedVector2Array:
	var retpoly:PackedVector2Array=[]
	var last_dir:Vector2 = (poly[0]-poly[-1]).normalized()
	for idx in range(poly.size()):
		var dir:Vector2 = (poly[(idx+1)%poly.size()]-poly[idx]).normalized()
		if(dir.dot(last_dir)<(1-limit)):
			retpoly.push_back(poly[idx])
			last_dir = dir
	return retpoly

func _ready()->void:
	generate()

static func is_polygon_self_intersecting(poly:PackedVector2Array)->bool:
	for n in range(poly.size()):
		for i in range(poly.size()):
			if(i==n||i==n-1||i==n+1||(i==0&&n==poly.size()-1)||(i==poly.size()-1&&n==0)):
				continue
			if(Geometry2D.segment_intersects_segment(poly[n-1],poly[n],poly[i-1],poly[i])):
				return true
	return false
		

func generate()->void:
	if(!is_inside_tree()):
		return
		
	var rand:RandomNumberGenerator = RandomNumberGenerator.new()
	rand.seed = noise.seed
	
	var stretch:float = rand.randf()*stretch_limit
	var rot:float = TAU*rand.randf()
	noise.set_block_signals(true)
	noise.frequency = 4.0/radius
	noise.set_block_signals(false)
	
	var poly:PackedVector2Array = []
	
	for s in range(8):
		var subshape:PackedVector2Array=[]
		var bias:Vector2
		bias.x = rand.randf_range(-1,1)*radius/2
		bias.y = rand.randf_range(-1,1)*radius/2
		bias *= Vector2(1+stretch,1-stretch)
		bias = bias.rotated(rot)
		for p in range(32):
			var point:Vector2 = Vector2.from_angle(rand.randf()*TAU)*rand.randf()*radius/2.5
			subshape.push_back(point+bias)
		subshape = Geometry2D.convex_hull(subshape)
		poly = Geometry2D.merge_polygons(poly,subshape)[0]
	poly = change_poly_resolution(poly,radius/4)
	
	var normals:PackedVector2Array = calc_poly_normals(poly)
	for n in range(poly.size()):
		var nval:float = noise.get_noise_2dv(poly[n])
		poly[n] += normals[n] * nval * noise_strength * radius
	
	poly = change_poly_resolution(poly,resolution)
	
	normals = calc_poly_normals(poly)
	for n in range(poly.size()):
		var nval:float = noise.get_noise_2dv(poly[n])
		poly[n] += normals[n] * nval * noise_strength * radius
	
	poly = change_poly_resolution(poly,resolution)
	poly = optimize_curvature(poly,curvature_limit)
	if(is_polygon_self_intersecting(poly)):
		return
	
	$Polygon2D.polygon = poly
	$CollisionPolygon2D.polygon = poly
