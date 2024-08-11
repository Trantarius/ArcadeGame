extends Node

@export var main:Control
@export var leaderboard:Control
@export var settings:Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file('res://main.tscn')


func _on_leaderboard_button_pressed() -> void:
	leaderboard.show()
	main.hide()


func _on_settings_button_pressed() -> void:
	main.hide()
	settings.show()
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	leaderboard.hide()
	main.show()
