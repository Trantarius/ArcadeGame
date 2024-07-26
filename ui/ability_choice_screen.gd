class_name AbilityChoiceScreen
extends Control

@export var card_container:HBoxContainer
@export var controls_label:RichTextLabel

const ability_card_scene:PackedScene = preload("res://ui/ability_card.tscn")

signal select_finished(ability:PlayerAbility)

func add_ability(ability:PlayerAbility)->void:
	var card:AbilityCard = ability_card_scene.instantiate()
	card.ability = ability
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

func _on_card_selected(card:AbilityCard)->void:
	get_tree().paused=false
	select_finished.emit(card.ability)
	queue_free()
