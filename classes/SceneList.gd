class_name SceneList
extends Resource

@export var list:Array[PackedScene]

func get_scene_name(idx:int)->String:
	if(idx<0||idx>=list.size()):
		return ''
	if(!is_instance_valid(list[idx])):
		return ''
	var state:SceneState = list[idx].get_state()
	return state.get_node_name(0)

## Gets a property from a scene without instantiating it. Only works with script properties.
func get_scene_prop(idx:int, prop:StringName, default:Variant=null)->Variant:
	
	var state:SceneState = list[idx].get_state()
	
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
