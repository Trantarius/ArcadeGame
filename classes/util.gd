extends Node

## Cumulative in-game time. Affected by Engine.time_scale and scene tree pausing.
var game_time:float

func _process(delta: float) -> void:
	game_time+=delta

## Determines if a physics body would fit at a particular location. The body does not have to be in the tree or active.
func does_body_fit(body:PhysicsBody2D, tform:Transform2D)->bool:
	var space:PhysicsDirectSpaceState2D = get_viewport().find_world_2d().direct_space_state
	
	for idx:int in range(PhysicsServer2D.body_get_shape_count(body.get_rid())):
		var shape:RID = PhysicsServer2D.body_get_shape(body.get_rid(),idx)
		var shape_tf:Transform2D = PhysicsServer2D.body_get_shape_transform(body.get_rid(),idx)
		var query:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape_rid = shape
		query.transform = tform * shape_tf
		query.collision_mask = body.collision_mask
		var result:Dictionary = space.get_rest_info(query)
		if(!result.is_empty()):
			return false
	
	return true

## Determines if an area would fit at a particular location. The area does not have to be in the tree or active.
func does_area_fit(area:Area2D, tform:Transform2D)->bool:
	var space:PhysicsDirectSpaceState2D = get_viewport().find_world_2d().direct_space_state
	
	for idx:int in range(PhysicsServer2D.area_get_shape_count(area.get_rid())):
		var shape:RID = PhysicsServer2D.area_get_shape(area.get_rid(),idx)
		var shape_tf:Transform2D = PhysicsServer2D.area_get_shape_transform(area.get_rid(),idx)
		var query:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape_rid = shape
		query.transform = tform * shape_tf
		query.collision_mask = area.collision_mask
		var result:Dictionary = space.get_rest_info(query)
		if(!result.is_empty()):
			return false
	
	return true

## Tries to find a place to put a body using [param locator] to produce candidate global transforms.
func attempt_place_body(body:PhysicsBody2D, parent:Node, locator:Callable, max_attempts:int)->bool:
	var transform:Transform2D = locator.call()
	if(does_body_fit(body,transform)):
		body.global_transform = transform
		parent.add_child.bind(body).call_deferred()
		return true
	elif(max_attempts>1):
		return attempt_place_body(body,parent,locator,max_attempts-1)
	else:
		return false

## Tries to find a place to put an actor using [param locator] to produce candidate global transforms.
func attempt_place_actor(actor:Actor, parent:Node, locator:Callable, max_attempts:int)->bool:
	actor.global_transform = Transform2D.IDENTITY
	var transform:Transform2D = locator.call()
	var fits:bool = true
	var bodies:Array[Node] = actor.find_children('*','PhysicsBody2D')
	for body:PhysicsBody2D in bodies:
		if(!does_body_fit(body,transform*body.global_transform)):
			fits=false
			break
	if(fits):
		actor.global_transform = transform
		parent.add_child(actor)
		return true
	elif(max_attempts>1):
		return attempt_place_actor(actor,parent,locator,max_attempts-1)
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
