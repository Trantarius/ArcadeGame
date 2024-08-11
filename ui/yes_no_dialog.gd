@tool
extends Control

@export_multiline var text:String:
	set(to):
		text = to
		if(!is_inside_tree()):
			await tree_entered
		$PanelContainer/PanelContainer/VBoxContainer/PanelContainer/Label.text = text

signal response(answer:bool)

func _on_no_button_pressed() -> void:
	response.emit(false)
	hide()


func _on_yes_button_pressed() -> void:
	response.emit(true)
	hide()
