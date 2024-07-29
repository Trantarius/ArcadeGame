@tool
class_name UpgradeCard
extends Control

@export var title_node:Label
@export var type_node:RichTextLabel
@export var description_node:RichTextLabel
@export var focus_node:Control

@export var upgrade:Upgrade:
	set(to):
		upgrade = to
		if(is_instance_valid(upgrade)):
			title_node.text = upgrade.upgrade_name
			match upgrade.rarity:
				Upgrade.COMMON:
					type_node.text = '[center][i]Common Upgrade[/i][/center]'
				Upgrade.RARE:
					type_node.text = '[center][i]Rare Upgrade[/i][/center]'
			description_node.text = Util.custom_format_string(upgrade.description, upgrade)
		else:
			title_node.text = 'Name'
			type_node.text = '[center][i]%s[/i][/center]'%['Type']
			description_node.text = 'Description'

signal pressed

func _ready() -> void:
	if(!is_instance_valid(upgrade)):
		upgrade=null

func _on_focus_entered() -> void:
	focus_node.show()

func _on_focus_exited() -> void:
	focus_node.hide()

func _gui_input(event: InputEvent) -> void:
	if(event.is_action('ui_accept') || (event is InputEventMouseButton && event.button_index==MOUSE_BUTTON_LEFT)):
		pressed.emit()
