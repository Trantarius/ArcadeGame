extends Node2D

@export var rect:Rect2
@export var linear_velocity:Vector2
@export var angular_velocity:float
@export var explosiveness:float
@export var shard_splits:int = 4

func shatter()->void:
	$SubViewport.size = rect.size
	var rectpoly:PackedVector2Array = [rect.position,Vector2(rect.position.x,rect.end.y), rect.end, Vector2(rect.end.x,rect.position.y)]
	shatter_polygon(rectpoly,shard_splits)

func _process(delta: float) -> void:
	position += linear_velocity*delta
	modulate.a = ($ReversibleTimer.time/$ReversibleTimer.duration)**2

func adopt(node:Node2D)->void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	global_transform = node.global_transform
	if(&'linear_velocity' in node):
		linear_velocity = node.linear_velocity
	if(&'angular_velocity' in node):
		angular_velocity = node.angular_velocity
	if(&'radius' in node):
		rect = Rect2(-node.radius,-node.radius,node.radius*2,node.radius*2)
	if(is_instance_valid(node.get_parent())):
		node.reparent($SubViewport)
	else:
		$SubViewport.add_child(node)
	node.global_transform = Transform2D.IDENTITY
	

func shatter_polygon(poly:PackedVector2Array, depth:int)->void:
	
	# https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
	var A:float = 0
	var centroid:Vector2
	for n:int in range(poly.size()):
		var va:Vector2 = poly[n]
		var vb:Vector2 = poly[(n+1)%poly.size()]
		var s = va.x*vb.y-vb.x*va.y
		centroid += (va+vb)*s
		A += s
	centroid/=3*A
	
	if(depth>0):
		var theta:float = randf()*TAU
		var c1:Vector2 = centroid + Vector2.from_angle(theta)*rect.size.length()/2
		var c2:Vector2 = centroid - Vector2.from_angle(theta)*rect.size.length()/2
		var cut:PackedVector2Array = Geometry2D.offset_polyline([c1,c2],0.5)[0]
		for sub:PackedVector2Array in Geometry2D.clip_polygons(poly,cut):
			shatter_polygon(sub, depth-1)
	
	else:
		var gon:Polygon2D = preload("res://visual_effects/shatter_shard.gd").new()
		gon.polygon = poly
		gon.offset = -centroid
		gon.linear_velocity = centroid*explosiveness + centroid.orthogonal()*angular_velocity
		gon.angular_velocity = randfn(0,0.5)*explosiveness - angular_velocity
		gon.position = centroid
		gon.texture = $SubViewport.get_texture()
		gon.texture_offset = -rect.position + centroid
		add_child(gon)
	
	
	
	
	
	#var perim:float = 0
	#for n:int in range(poly.size()):
		#perim += (poly[n]-poly[n-1]).length()
	#
	## pick 2 random points on the perimeter of the polygon, which are not on the same edge
	#var w1:float = randf()*perim
	#var w2:float = fposmod(w1+perim/2,perim)
	#var i1a:int = -1
	#var i1b:int = -1
	#var i2a:int = -1
	#var i2b:int = -1
	#var p1:Vector2 = lerp(poly[i1a],poly[i1b],fposmod(w1,1))
	#var p2:Vector2 = lerp(poly[i2a],poly[i2b],fposmod(w2,1))
	#perim=0
	#for n:int in range(poly.size()):
		#var len:float = (poly[(n+1)%poly.size()]-poly[n]).length()
		#if(w1>0 && len>=w1 && i1a<0):
			#i1a=n
			#i1b=(i1a+1)%poly.size()
			#p1=lerp(poly[i1a],poly[i1b],w1/len)
		#else:
			#w1 -= len
		#if(w2>0 && len>=w2 && i2a<0):
			#i2a=n
			#i2b=(i2a+1)%poly.size()
			#p2=lerp(poly[i2a],poly[i2b],w2/len)
		#else:
			#w2 -= len
	#
	## create [p1,i1b,...,i2a,p2]
	#var s1:PackedVector2Array = [p1]
	#if(i1b<=i2a):
		#s1.append_array(poly.slice(i1b,i2a+1))
	#else:
		#s1.append_array(poly.slice(i1b))
		#s1.append_array(poly.slice(0,i2a+1))
	#s1.push_back(p2)
	#
	## create [p2,i2b,...,i1a,p1]
	#var s2:PackedVector2Array = [p2]
	#if(i2b<=i1a):
		#s2.append_array(poly.slice(i2b,i1a+1))
	#else:
		#s2.append_array(poly.slice(i2b))
		#s2.append_array(poly.slice(0,i1a+1))
	#s2.push_back(p1)
	#
	#return [s1,s2]


func _on_reversible_timer_timeout() -> void:
	queue_free()
