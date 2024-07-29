class_name UpgradeChoiceScreen
extends Control

@export var card_container:HBoxContainer
@export var controls_label:RichTextLabel

const upgrade_card_scene:PackedScene = preload("res://ui/upgrade_card.tscn")

signal select_finished(upgrade:Upgrade)

func add_upgrade(upgrade:Upgrade)->void:
	var card:UpgradeCard = upgrade_card_scene.instantiate()
	card.upgrade = upgrade
	card_container.add_child(card)
	card.pressed.connect(_on_card_selected.bind(card))
	
func begin_selection()->void:
	assert(card_container.get_child_count()>0)
	get_tree().paused = true
	if(card_container.get_child_count()==1):
		card_container.get_child(0).grab_focus.call_deferred()
		controls_label.text = Util.custom_format_string('[center]{action ui_accept} confirm[/center]',null)
	else:
		focus_neighbor_left = card_container.get_child(0).get_path()
		focus_neighbor_right = card_container.get_child(card_container.get_child_count()-1).get_path()
		grab_focus.call_deferred()
		controls_label.text = Util.custom_format_string('[center]{action left}/{action right} select    {action ui_accept} confirm[/center]',null)

func _on_card_selected(card:UpgradeCard)->void:
	get_tree().paused=false
	select_finished.emit(card.upgrade)
	queue_free()
