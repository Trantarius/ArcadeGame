@tool
class_name HealthBar
extends ProgressBar

@export var show_text:bool = false:
	set(to):
		if(show_text!=to && is_instance_valid(label)):
			label.visible = to
			if(to):
				custom_minimum_size = label.get_combined_minimum_size()
				label.minimum_size_changed.connect(_on_label_minimum_size_changed)
			else:
				label.minimum_size_changed.disconnect(_on_label_minimum_size_changed)
				custom_minimum_size = Vector2.ZERO
		show_text = to

var label:Label

func _ready() -> void:
	theme_type_variation = 'HealthBar'
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.theme_type_variation = 'HealthBar'
	label.visible = show_text
	label.text = '%d/%d'%[ceil(value),ceil(max_value)]
	add_child(label, false, Node.INTERNAL_MODE_BACK)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if(show_text):
		custom_minimum_size = label.get_combined_minimum_size()
		label.minimum_size_changed.connect(_on_label_minimum_size_changed)

func _on_label_minimum_size_changed()->void:
	custom_minimum_size = label.get_combined_minimum_size()

func _on_health_changed(new_health:float, new_max_health:float)->void:
	max_value = new_max_health
	value = new_health

func _draw() -> void:
	label.text = '%d/%d'%[ceil(value),ceil(max_value)]
