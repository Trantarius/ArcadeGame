extends PanelContainer

@export var username_line:LineEdit
@export var bad_username_icon:TextureRect
@export var good_username_icon:TextureRect

@export var auto_submit_button:CheckButton


func _ready()->void:
	refresh()

func refresh()->void:
	if(GlobalMonitor.username=='Anonymous'):
		username_line.text = ''
	else:
		username_line.text = GlobalMonitor.username
	
	auto_submit_button.button_pressed = GlobalMonitor.telemetry_enabled

func _on_username_line_text_changed(new_text: String) -> void:
	if(new_text.is_empty()):
		bad_username_icon.hide()
		good_username_icon.show()
		return
	var err:String = Util.verify_username(new_text)
	if(err==""):
		bad_username_icon.hide()
		good_username_icon.show()
	else:
		good_username_icon.hide()
		bad_username_icon.tooltip_text = err
		bad_username_icon.show()

func apply()->void:
	if(username_line.text==''):
		GlobalMonitor.username = 'Anonymous'
	elif(Util.verify_username(username_line.text)==''):
		GlobalMonitor.username = username_line.text
	GlobalMonitor.telemetry_enabled = auto_submit_button.button_pressed

func go_back()->void:
	refresh()
	$'../Main'.show()
	hide()

func _on_back_button_pressed() -> void:
	var username:String = username_line.text
	if(username.is_empty()):
		username='Anonymous'
	if(username!=GlobalMonitor.username || auto_submit_button.button_pressed!=GlobalMonitor.telemetry_enabled):
		$UnsavedChangesPopup.show()
		var response:bool = await $UnsavedChangesPopup.response
		if(response):
			apply()
	go_back()


func _on_apply_button_pressed() -> void:
	apply()
	go_back()
