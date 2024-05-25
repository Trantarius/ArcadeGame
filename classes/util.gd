extends Node

## Cumulative in-game time. Affected by Engine.time_scale and scene tree pausing.
var game_time:float

func _process(delta: float) -> void:
	game_time+=delta

## Limits an angle to be between left and right. The difference between left and right must be less than PI. 
func angle_clamp(angle:float, left:float, right:float)->float:
	if(angle_difference(angle,left)>0):
		return left
	if(angle_difference(angle,right)<0):
		return right
	return angle

## Determines if the physics bodies contained by this node would fit at a particular location. 
## The node does not have to be in the tree or active.
func does_node_fit(node:Node2D, tform:Transform2D)->bool:
	if(node is PhysicsBody2D):
		var space:PhysicsDirectSpaceState2D = get_viewport().find_world_2d().direct_space_state
		
		for idx:int in range(PhysicsServer2D.body_get_shape_count(node.get_rid())):
			var shape:RID = PhysicsServer2D.body_get_shape(node.get_rid(),idx)
			var shape_tf:Transform2D = PhysicsServer2D.body_get_shape_transform(node.get_rid(),idx)
			var query:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
			query.shape_rid = shape
			query.transform = tform * shape_tf
			query.collision_mask = node.collision_mask
			var result:Array[Dictionary] = space.intersect_shape(query,1)
			if(!result.is_empty()):
				return false
	
	for child:Node in get_children():
		if(child is Node2D):
			if(!does_node_fit(child,tform * child.transform)):
				return false
	
	return true

## Tries to find a place to put a node using [param locator] to produce candidate global transforms.
func attempt_place_node(node:Node2D, parent:Node, locator:Callable, max_attempts:int)->bool:
	var transform:Transform2D = locator.call()
	if(does_node_fit(node,transform)):
		node.transform = transform
		parent.add_child.call_deferred(node)
		return true
	elif(max_attempts>1):
		return attempt_place_node(node,parent,locator,max_attempts-1)
	else:
		return false

## Finds the position and direction of a contact between two particular shapes in the given colliders.
## Used to get collision position/direction from [signal Area2D.area_shape_entered].
## Returns {'position':Vector2, 'normal':Vector2}, or {} if there is no collision.
func collider_get_shape_contact(collider_a:CollisionObject2D, shape_idx_a:int, collider_b:CollisionObject2D, shape_idx_b:int)->Dictionary:
	var shape_owner_a:int = collider_a.shape_find_owner(shape_idx_a)
	var shape_id_a:int = -1
	for i:int in range(collider_a.shape_owner_get_shape_count(shape_owner_a)):
		if(collider_a.shape_owner_get_shape_index(shape_owner_a,i)==shape_idx_a):
			shape_id_a=i
			break
	if(shape_id_a<0):
		push_error("couldn't find shape_idx_a in collider_a")
		return {}
	var shape_a:Shape2D = collider_a.shape_owner_get_shape(shape_owner_a, shape_id_a)
	var shape_tform_a:Transform2D = collider_a.global_transform * collider_a.shape_owner_get_transform(shape_owner_a)
	
	var shape_owner_b:int = collider_b.shape_find_owner(shape_idx_b)
	var shape_id_b:int = -1
	for i:int in range(collider_b.shape_owner_get_shape_count(shape_owner_b)):
		if(collider_b.shape_owner_get_shape_index(shape_owner_b,i)==shape_idx_b):
			shape_id_b=i
			break
	if(shape_id_b<0):
		push_error("couldn't find shape_idx_b in collider_b")
		return {}
	var shape_b:Shape2D = collider_b.shape_owner_get_shape(shape_owner_b, shape_id_b)
	var shape_tform_b:Transform2D = collider_b.global_transform * collider_b.shape_owner_get_transform(shape_owner_b)
	
	var contacts:PackedVector2Array = shape_a.collide_and_get_contacts(shape_tform_a, shape_b, shape_tform_b)
	if(contacts.is_empty()):
		return {}
	
	var pos:Vector2 = Vector2.ZERO
	var norm:Vector2 = Vector2.ZERO
	for i:int in range(0,contacts.size(),2):
		pos += (contacts[i]+contacts[i+1])/2
		norm += (contacts[i+1]-contacts[i]).normalized()
	pos /= contacts.size()/2
	norm /= contacts.size()/2
	return {&'position':pos, &'normal':norm}

## Simplified interface for a complex raycast. [param penetration] is how many collisions to pass through and return.
## If a collision happens in the same place as another, it is considered the same even if it is with a different collider.
## Returns an array of results from [method PhysicsDirectSpaceState2D.intersect_ray].
func raycast(from:Vector2, to:Vector2, collision_mask:int, penetration:int = 1,
	include_areas:bool = true, include_bodies:bool = true, exclude:Array[CollisionObject2D]=[])->Array[Dictionary]:
	
	var space:PhysicsDirectSpaceState2D = get_viewport().find_world_2d().direct_space_state
	
	var results:Array[Dictionary] = []
	var hit_count:int = 0
	var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.collide_with_areas = include_areas
	query.collide_with_bodies = include_bodies
	query.collision_mask = collision_mask
	query.from = from
	query.to = to
	query.exclude = exclude.map(func(body:CollisionObject2D)->RID: return body.get_rid())
	while(hit_count <= penetration):
		var res:Dictionary = space.intersect_ray(query)
		if(res.is_empty()):
			break
		if(results.is_empty() || !((res.position-results.back().position).length()<0.1)):
			hit_count += 1
		if(hit_count <= penetration):
			results.push_back(res)
		query.exclude = query.exclude + [res.rid]
	return results

## Gets a [Shape2D] resource from a collider, based on the shape index.
func collider_get_shape2d(collider:CollisionObject2D, shape_idx:int)->Shape2D:
	var shape_owner:int = collider.shape_find_owner(shape_idx)
	var shape_id:int = -1
	for i:int in range(collider.shape_owner_get_shape_count(shape_owner)):
		if(collider.shape_owner_get_shape_index(shape_owner,i)==shape_idx):
			shape_id=i
			break
	if(shape_id<0):
		return null
	return collider.shape_owner_get_shape(shape_owner, shape_id)
