extends MarginContainer

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

@onready var left_card:Control = $AspectRatioContainer/PanelContainer/HBoxContainer/AbilityCard
@onready var right_card:Control = $AspectRatioContainer/PanelContainer/HBoxContainer/AbilityCard2

signal select_finished(ability:PlayerAbility)

func _ready()->void:
	get_tree().paused = true
	if(is_instance_valid(left_ability)):
		left_card.build_from(left_ability)
	if(is_instance_valid(right_ability)):
		right_card.build_from(right_ability)
	
func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if(event.is_action('left')):
		left_card.highlighted = true
		right_card.highlighted = false
	elif(event.is_action('right')):
		right_card.highlighted = true
		left_card.highlighted = false
	elif(event.is_action('shoot')):
		if(left_card.highlighted):
			get_tree().paused = false
			select_finished.emit(left_ability)
			queue_free()
		elif(right_card.highlighted):
			get_tree().paused = false
			select_finished.emit(right_ability)
			queue_free()
