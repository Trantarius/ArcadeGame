@tool
class_name AbilityCard
extends PanelContainer

@export var highlighted:bool:
	set(to):
		if(has_node(^'Highlight')):
			$Highlight.visible = to
	get:
		if(has_node(^'Highlight')):
			return $Highlight.visible
		else:
			return false

@export var title:String:
	set(to):
		if(has_node(^'VBoxContainer/Title')):
			$VBoxContainer/Title.text = to
	get:
		if(has_node(^'VBoxContainer/Title')):
			return $VBoxContainer/Title.text
		else:
			return ''

@export var texture:Texture2D:
	set(to):
		if(has_node(^'VBoxContainer/TextureRect')):
			$VBoxContainer/TextureRect.texture = to
	get:
		if(has_node(^'VBoxContainer/TextureRect')):
			return $VBoxContainer/TextureRect.texture
		else:
			return null

const type_prefix:String='[center][i]'
const type_suffix:String='[/i][/center]'
@export var type:String:
	set(to):
		if(has_node(^'VBoxContainer/Type')):
			$VBoxContainer/Type.text = type_prefix + to + type_suffix
	get:
		if(has_node(^'VBoxContainer/Type')):
			return $VBoxContainer/Type.text.trim_prefix(type_prefix).trim_suffix(type_suffix)
		return ''

@export_multiline var description:String:
	set(to):
		if(has_node(^'VBoxContainer/Description')):
			$VBoxContainer/Description.text = to
	get:
		if(has_node(^'VBoxContainer/Description')):
			return $VBoxContainer/Description.text
		else:
			return ''

@export var state:String:
	set(to):
		if(has_node(^'VBoxContainer/State')):
			$VBoxContainer/State.text = to
	get:
		if(has_node(^'VBoxContainer/State')):
			return $VBoxContainer/State.text
		else:
			return ''

func build_from(ability:PlayerAbility)->void:
	title = ability.ability_name
	#if(is_instance_valid(ability.texture)):
	texture = ability.texture
	type = ability.type
	description = AbilityCard.format_description(ability)
	if(ability.is_active):
		state = 'Equipped'
	else:
		state = 'New'

## Handles some special escapes and turns them into BBCode
static func format_description(ability:PlayerAbility)->String:
	var input:String = ability.description
	var escape_rex:RegEx = RegEx.create_from_string("\\{\\s*(\\w+)\\s*(\\S+)?\\s*\\}")
	var found:RegExMatch = escape_rex.search(input)
	while(is_instance_valid(found)):
		input = input.erase(found.get_start(),found.get_end()-found.get_start())
		match found.get_string(1):
			'action':
				if(found.get_group_count()<2):
					push_error("bad description string escape '",found.get_string(),"'")
				else:
					var action:String = found.get_string(2)
					
					var repl:String
					var events:Array[InputEvent] = InputMap.action_get_events(action)
					if(events.is_empty()):
						repl = '[lb][rb]'
					else:
						repl = '[lb]'
						repl += events[0].as_text().trim_suffix(' (Physical)')
						for i:int in range(1,events.size()):
							repl += '|' + events[i].as_text().trim_suffix(' (Physical)')
						repl += '[rb]'
						
					repl = '[code]'+repl+'[/code]'
					input = input.insert(found.get_start(),repl)
			
			'property':
				if(found.get_group_count()<2):
					push_error("bad description string escape '",found.get_string(),"'")
				else:
					var prop:String = found.get_string(2)
					var value:Variant = ability.get(prop)
					input = input.insert(found.get_start(),str(value))
			_:
				push_error("bad description string escape '",found.get_string(),"'")
		found = escape_rex.search(input)
	return input
