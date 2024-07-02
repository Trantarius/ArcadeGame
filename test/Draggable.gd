extends Control

var is_dragging:bool = false
signal moved

func _gui_input(event: InputEvent) -> void:
	if(event is InputEventMouseButton && event.button_index==MOUSE_BUTTON_LEFT):
		is_dragging = event.is_pressed()
	if(event is InputEventMouseMotion && is_dragging):
		position += event.relative
		moved.emit()

func _input(event: InputEvent) -> void:
	if(event is InputEventMouseButton && event.button_index==MOUSE_BUTTON_LEFT && !event.is_pressed()):
		is_dragging = false
