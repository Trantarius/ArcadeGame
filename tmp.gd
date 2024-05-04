@tool
extends EditorScript


func _run() -> void:
	get_scene().noise.seed=randi()
	get_scene().generate()
