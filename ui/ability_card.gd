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
			$VBoxContainer/TextureRect.texture = texture
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
	if(is_instance_valid(ability.texture)):
		texture = ability.texture
	type = ability.type
	description = ability.description
	if(ability.is_active):
		state = 'Equipped'
	else:
		state = 'New'
