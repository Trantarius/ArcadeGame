@tool
class_name Util

## Cumulative in-game time. Affected by Engine.time_scale and scene tree pausing.
static var game_time:float
static var __last_tick:int

static func _static_init() -> void:
	if(!Engine.is_editor_hint()):
		Engine.get_main_loop().process_frame.connect(_process)

static func _process() -> void:
	var now:int = Time.get_ticks_usec()
	if(!Engine.get_main_loop().paused):
		game_time += Engine.time_scale * float(now-__last_tick)/1_000_000
	__last_tick = now

## Checks if a username is valid. Returns an error message if invalid, otherwise returns an empty string.
static func verify_username(username:String)->String:
	if(username.is_empty()):
		return "username cannot be empty"
	if(username.strip_edges()!=username):
		return "username cannot begin or end with whitespace"
	if(username.length()>32):
		return "username cannot be longer than 32 characters"
	var font:Font = load('res://ui/theme/Montserrat-Regular.ttf')
	for n:int in range(username.length()):
		if(!font.has_char(username.unicode_at(n))):
			return "username contains an invalid character"
	var size:Vector2 = font.get_string_size(username)
	if(size.x>200):
		return "username cannot be more than 200px wide"
	return ""

## Limits an angle to be between left and right. The difference between left and right must be less than PI. 
static func angle_clamp(angle:float, left:float, right:float)->float:
	if(angle_difference(angle,left)>0):
		return left
	if(angle_difference(angle,right)<0):
		return right
	return angle

## Determines if the physics bodies contained by this node would fit at a particular location. 
## The node does not have to be in the tree or active.
static func does_node_fit(node:Node2D, tform:Transform2D)->bool:
	if(node is PhysicsBody2D):
		var space:PhysicsDirectSpaceState2D = Engine.get_main_loop().root.find_world_2d().direct_space_state
		
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
	
	for child:Node in node.get_children():
		if(child is Node2D):
			if(!does_node_fit(child,tform * child.transform)):
				return false
	
	return true

## Tries to find a place to put a node using [param locator] to produce candidate global transforms.
static func attempt_place_node(node:Node2D, parent:Node, locator:Callable, max_attempts:int)->bool:
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
static func collider_get_shape_contact(collider_a:CollisionObject2D, shape_idx_a:int, collider_b:CollisionObject2D, shape_idx_b:int)->Dictionary:
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
static func raycast(from:Vector2, to:Vector2, collision_mask:int, penetration:int = 1,
	include_areas:bool = true, include_bodies:bool = true, exclude:Array[CollisionObject2D]=[])->Array[Dictionary]:
	
	var space:PhysicsDirectSpaceState2D = Engine.get_main_loop().root.find_world_2d().direct_space_state
	
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
static func collider_get_shape2d(collider:CollisionObject2D, shape_idx:int)->Shape2D:
	var shape_owner:int = collider.shape_find_owner(shape_idx)
	var shape_id:int = -1
	for i:int in range(collider.shape_owner_get_shape_count(shape_owner)):
		if(collider.shape_owner_get_shape_index(shape_owner,i)==shape_idx):
			shape_id=i
			break
	if(shape_id<0):
		return null
	return collider.shape_owner_get_shape(shape_owner, shape_id)

## Parses a string for {{...}}, and evaluates the contents as an expression.
static func expr_escape_string(string:String, obj:Object=null, vars:Dictionary={})->String:
	var rex:RegEx = RegEx.create_from_string("{{(.*?)}}")
	var mch:RegExMatch = rex.search(string)
	while(is_instance_valid(mch)):
		string = string.erase(mch.get_start(), mch.get_end()-mch.get_start())
		var exstr:String = mch.get_string(1)
		var expr:Expression = Expression.new()
		var err:Error = expr.parse(exstr,vars.keys())
		if(err!=OK):
			push_error(expr.get_error_text())
			break
		var out:Variant = expr.execute(vars.values(),obj)
		if(expr.has_execute_failed()):
			push_error(expr.get_error_text())
			break
		string = string.insert(mch.get_start(), str(out))
		mch = rex.search(string)
	return string

## Gets a string describing the controls bound to an InputAction.
static func get_controls_string(action:StringName)->String:
	var ret:String
	var events:Array[InputEvent] = InputMap.action_get_events(action)
	if(events.is_empty()):
		ret = '[lb][rb]'
	else:
		ret = '[lb]'
		ret += events[0].as_text().trim_suffix(' (Physical)')
		for i:int in range(1,events.size()):
			ret += '|' + events[i].as_text().trim_suffix(' (Physical)')
		ret += '[rb]'
	return '[code]'+ret+'[/code]'

## Handles some special escapes and turns them into BBCode. [br]
## [code]{action <actionname>}[/code] will insert the current keybind for the input action with name [code]actionname[/code].[br]
## [code]{property <propname> <format?>}[/code] will retrieve a property named [code]propname[/code] from the given object.[br]
## [code]{stat <statname> <format?>}[/code] will describe a [Stat], using the given unit if present.
static func custom_format_string(input:String, obj:Object)->String:
	var escape_rex:RegEx = RegEx.create_from_string("\\{\\s*(\\w+?)(?:\\s+(\\S+?))?(?:\\s+(\\S+?))?\\s*\\}")
	var found:RegExMatch = escape_rex.search(input)
	while(is_instance_valid(found)):
		input = input.erase(found.get_start(),found.get_end()-found.get_start())
		match found.get_string(1):
			'action':
				var action:String = found.get_string(2)
				if(!InputMap.has_action(action)):
					var err:String = 'nonexistent action \''+action+'\''
					if(!Engine.is_editor_hint()):
						push_error("bad custom format string: '",found.get_string(),"' "+err)
					input = input.insert(found.get_start(),'[code][color=red]ERROR '+err+'[/color][/code]')
				else:
					input = input.insert(found.get_start(),get_controls_string(action))
			
			'property':
				var prop:String = found.get_string(2)
				if(!(prop in obj)):
					var err:String = 'object doesn\'t have property \''+prop+'\''
					if(!Engine.is_editor_hint()):
						push_error("bad custom format string: '",found.get_string(),"' "+err)
					input = input.insert(found.get_start(),'[code][color=red]ERROR '+err+'[/color][/code]')
				else:
					var value:Variant = obj.get(prop)
					var vstr:String
					if(!found.get_string(3).is_empty()):
						vstr = found.get_string(3)%[value]
					else:
						vstr = str(value)
					input = input.insert(found.get_start(),'[code]'+vstr+'[/code]')
			
			'stat':
				var prop:String = found.get_string(2)
				if(!(prop in obj) || !(obj.get(prop) is Stat)):
					var err:String = 'object doesn\'t have property \''+prop+'\' or it isn\'t a Stat'
					if(!Engine.is_editor_hint()):
						push_error("bad custom format string: '",found.get_string(),"' "+err)
					input = input.insert(found.get_start(),'[code][color=red]ERROR '+err+'[/color][/code]')
				else:
					var stat:Stat = obj.get(prop)
					var base_str:String
					var value_str:String
					if(!found.get_string(3).is_empty()):
						base_str = found.get_string(3)%[stat.base]
						value_str = found.get_string(3)%[stat.get_value()]
					else:
						base_str = str(stat.base)
						value_str = str(stat.get_value())
					
					var desc:String = base_str
					if(is_equal_approx(stat.get_value(),stat.base)):
						pass
					elif(stat.get_value()>stat.base):
						desc += ' ([hint='+stat.get_explanation()+'][color=green]'+value_str+'[/color][/hint])'
					else:
						desc += ' ([hint='+stat.get_explanation()+'][color=red]'+value_str+'[/color][/hint])'
						
					input = input.insert(found.get_start(),'[code]'+desc+'[/code]')
			_:
				var err:String = 'unknown escape type \''+found.get_string(1)+'\''
				if(!Engine.is_editor_hint()):
					push_error("bad custom format string: '",found.get_string(),"' "+err)
				input = input.insert(found.get_start(),'[code][color=red]ERROR '+err+'[/color][/code]')
		found = escape_rex.search(input)
	return input

## Gets a property from a scene without instantiating it. Only works with exported properties which are not the default value.
## Returns [param default] if the property is not available, or if it has not been set.
static func get_scene_prop(scene:PackedScene, prop:StringName, default:Variant=null)->Variant:
	if(!is_instance_valid(scene)):
		return default
	
	var state:SceneState = scene.get_state()
	
	for i:int in range(state.get_node_property_count(0)):
		if(state.get_node_property_name(0,i)==prop):
			return state.get_node_property_value(0,i)
	
	var script:Script
	for i:int in range(state.get_node_property_count(0)):
		if(state.get_node_property_name(0,i)==&'script'):
			script = state.get_node_property_value(0,i)
	if(!is_instance_valid(script)):
		return default
	
	var constmap:Dictionary = script.get_script_constant_map()
	if(constmap.has(prop)):
		return constmap[prop]
	else:
		return default

static func current_camera_pos()->Vector2:
	var vp:Viewport = Engine.get_main_loop().root
	var canv:Transform2D = vp.canvas_transform
	return canv.affine_inverse()*(Vector2(vp.size)/2)
