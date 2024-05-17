extends Node

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

## Tries to find a place to put a body using [param locator] to produce candidate global transforms.
func attempt_place_body(body:PhysicsBody2D, parent:Node, locator:Callable, max_attempts:int)->bool:
	var transform:Transform2D = locator.call()
	if(does_body_fit(body,transform)):
		body.global_transform = transform
		parent.add_child(body)
		return true
	elif(max_attempts>1):
		return attempt_place_body(body,parent,locator,max_attempts-1)
	else:
		return false
