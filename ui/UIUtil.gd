class_name UIUtil

## Gets a string describing the controls bound to an InputAction.
static func get_controls_string(action:StringName)->String:
	var ret:String
	var events:Array[InputEvent] = InputMap.action_get_events(action)
	if(events.is_empty()):
		ret = '[]'
	else:
		ret = '['
		ret += events[0].as_text().trim_suffix(' (Physical)')
		for i:int in range(1,events.size()):
			ret += '|' + events[i].as_text().trim_suffix(' (Physical)')
		ret += ']'
	return ret
