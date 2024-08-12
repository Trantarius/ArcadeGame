@tool
extends Control

@export_range(0,1) var fade_progress:float:
	set(to):
		fade_progress = to
		if(!is_inside_tree()):
			await tree_entered
		$GaussianX.material.set_shader_parameter('blur',fade_progress*max_blur)
		$GaussianY.material.set_shader_parameter('blur',fade_progress*max_blur)
		$Gray.color.a = fade_progress*max_gray
		$GameOverLabel.modulate.a = clamp(remap(fade_progress,0,0.3,0,1),0,1)
		$RunInfo.modulate.a = clamp(remap(fade_progress,0.15,0.45,0,1),0,1)
		$Options.modulate.a = clamp(remap(fade_progress,0.3,0.6,0,1),0,1)
		$Leaderboard.modulate.a = clamp(remap(fade_progress,0.6,0.9,0,1),0,1)
		if(!Engine.is_editor_hint()):
			Engine.time_scale = 1.0-fade_progress

@export var max_blur:float:
	set(to):
		max_blur = to
		if(!is_inside_tree()):
			await tree_entered
		$GaussianX.material.set_shader_parameter('blur',fade_progress*max_blur)
		$GaussianY.material.set_shader_parameter('blur',fade_progress*max_blur)

@export var max_gray:float:
	set(to):
		max_gray = to
		if(!is_inside_tree()):
			await tree_entered
		$Gray.color.a = fade_progress*max_gray

var timer:SceneTreeTimer
var fade_done:bool = false
var run:RunRecord:
	set(to):
		if(is_instance_valid(run)):
			run.submission_complete.disconnect(_on_run_submission_complete)
		run = to
		if(is_instance_valid(run)):
			run.submission_complete.connect(_on_run_submission_complete)

@onready var submission_status:Label = $Leaderboard/PanelContainer/VBoxContainer/SubmissionStatus
@onready var username_edit:LineEdit = $Leaderboard/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/UsernameEdit
@onready var submit_button:Button = $Leaderboard/PanelContainer/VBoxContainer/HBoxContainer/SubmitButton
@onready var bad_username:TextureRect = $Leaderboard/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/BadUsername
@onready var good_username:TextureRect = $Leaderboard/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/GoodUsername

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(Engine.is_editor_hint()):
		return
	timer = get_tree().create_timer(3,true,false,true)
	timer.timeout.connect(func()->void:
		fade_done = true
		fade_progress = 1.0
		get_tree().paused=true
		Engine.time_scale=1.0)

func _on_run_submission_complete()->void:
	$Leaderboard/PanelContainer/VBoxContainer/Leaderboard/Global.update()
	$Leaderboard/PanelContainer/VBoxContainer/Leaderboard/Local.update()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(Engine.is_editor_hint()):
		return
	if(!fade_done):
		fade_progress = 1.0-timer.time_left/3
	
	if(is_instance_valid(run)):
		if(run.submission_in_progress):
			submission_status.text = '.'.repeat((Time.get_ticks_msec()/500)%7+1)
		elif(run.has_been_submitted):
			submission_status.text = "Your run has been submitted. You can submit again to change the username."
		elif(run.submission_failed):
			submission_status.text = "Submission failed"
		else:
			submission_status.text = ""
		
		$RunInfo/BossKills.text = str(run.boss_kills)
		$RunInfo/Score.text = '%d'%[run.score]
		if(run.time>3600000):
			$RunInfo/Time.text = '%d:%02d:%02d'%[run.time/3600000, (run.time%3600000)/60000, (run.time%60000)/1000]
		else:
			$RunInfo/Time.text = '%d:%02d'%[run.time/60000, (run.time%60000)/1000]
	
	var user:String = username_edit.text
	if(user.is_empty()):
		user='Anonymous'
	var err:String = Util.verify_username(user)
	var user_good:bool = err.is_empty()
	submit_button.disabled = !user_good
	bad_username.visible = !user_good
	good_username.visible = user_good
	bad_username.tooltip_text = err


func _on_play_again_button_pressed() -> void:
	get_tree().paused=false
	Engine.time_scale=1.0
	get_tree().change_scene_to_file('res://main.tscn')

func _on_main_menu_button_pressed() -> void:
	get_tree().paused=false
	Engine.time_scale=1.0
	get_tree().change_scene_to_file('res://main_menu.tscn')


func _on_submit_button_pressed() -> void:
	if(is_instance_valid(run)):
		var user:String = username_edit.text
		if(user.is_empty()):
			user='Anonymous'
		if(Util.verify_username(user).is_empty()):
			run.username = user
			run.has_been_submitted = false
			run.save_file()
			run.submit()
