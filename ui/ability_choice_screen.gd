extends Control

var left_ability:PlayerAbility:
	set(to):
		left_ability=to
		if(is_inside_tree()):
			left_card.build_from(left_ability)
var right_ability:PlayerAbility:
	set(to):
		right_ability=to
		if(is_inside_tree()):
			right_card.build_from(right_ability)

@onready var left_card:Control = $PanelContainer/PanelContainer/HBoxContainer/MarginContainer/AbilityCard
@onready var right_card:Control = $PanelContainer/PanelContainer/HBoxContainer/MarginContainer2/AbilityCard

signal select_finished(ability:PlayerAbility)

func _ready()->void:
	get_tree().paused = true
	if(is_instance_valid(left_ability)):
		left_card.build_from(left_ability)
	if(is_instance_valid(right_ability)):
		right_card.build_from(right_ability)
	grab_focus.call_deferred()


func _on_left_card_button_pressed() -> void:
	get_tree().paused = false
	select_finished.emit(left_ability)
	queue_free()

func _on_right_card_button_pressed() -> void:
	get_tree().paused = false
	select_finished.emit(right_ability)
	queue_free()
