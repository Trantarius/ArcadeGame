@tool
class_name AbilityCard
extends Control

@export var title_node:Label
@export var texture_node:TextureRect
@export var type_node:RichTextLabel
@export var description_node:RichTextLabel
@export var state_node:Label
@export var focus_node:Control

@export var ability:PlayerAbility:
	set(to):
		ability = to
		if(is_instance_valid(ability)):
			title_node.text = ability.ability_name
			texture_node.texture = ability.texture
			type_node.text = '[center][i]%s[/i][/center]'%[ability.get_type_name()]
			description_node.text = Util.custom_format_string(ability.description, ability)
			state_node.text = 'Equipped' if ability.is_inside_tree() else 'New'
		else:
			title_node.text = 'Name'
			texture_node.texture = preload('res://icon.svg')
			type_node.text = '[center][i]%s[/i][/center]'%['Type']
			description_node.text = 'Description'
			state_node.text = 'State'

signal pressed

func _ready() -> void:
	if(!is_instance_valid(ability)):
		ability=null

func _on_focus_entered() -> void:
	focus_node.show()

func _on_focus_exited() -> void:
	focus_node.hide()

func _gui_input(event: InputEvent) -> void:
	if(event.is_action('ui_accept') || (event is InputEventMouseButton && event.button_index==MOUSE_BUTTON_LEFT)):
		pressed.emit()
