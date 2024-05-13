@tool
class_name InfoPanel
extends Control

@onready var score_label:Label = $VBoxContainer/ScoreLabel

@export var score:float:
	set(to):
		score = to
		if(is_inside_tree()):
			update_score()

func update_score()->void:
	score_label.text = "Score: " + str(floori(score))

@onready var health_bar:ProgressBar = $VBoxContainer/HealthBar
@onready var health_bar_label:Label = $VBoxContainer/HealthBar/Label

@export var health:float:
	set(to):
		health = to
		if(is_inside_tree()):
			update_health()

@export var max_health:float:
	set(to):
		max_health = to
		if(is_inside_tree()):
			update_health()

func update_health()->void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar_label.text = str(ceili(health)) + ' / ' + str(ceili(max_health))

@onready var ability_list:VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/MarginContainer/VBoxContainer

@export var include_controls_in_abilities:bool = true:
	set(to):
		include_controls_in_abilities = to
		if(is_inside_tree()):
			update_abilities()

@export var include_basic_controls_in_abilities:bool = false:
	set(to):
		include_basic_controls_in_abilities = to
		if(is_inside_tree()):
			update_abilities()

var abilities:Dictionary

func update_abilities()->void:
	
	if(include_basic_controls_in_abilities && include_controls_in_abilities):
		if(!abilities.has(&'Rotate')):
			var lbl:Label = Label.new()
			ability_list.add_child(lbl)
			abilities[&'Rotate']=lbl
		if(!abilities.has(&'Thrust')):
			var lbl:Label = Label.new()
			ability_list.add_child(lbl)
			abilities[&'Thrust']=lbl
		abilities[&'Rotate'].text = UIUtil.get_controls_string(&'left')+' '+UIUtil.get_controls_string(&'right')+' Rotate'
		abilities[&'Thrust'].text = UIUtil.get_controls_string(&'forward')+' Thrust'
		
	else:
		if(abilities.has(&'Rotate')):
			abilities[&'Rotate'].queue_free()
			abilities.erase(&'Rotate')
		if(!abilities.has(&'Thrust')):
			abilities[&'Thrust'].queue_free()
			abilities.erase(&'Thrust')
			
	var keys:Array = abilities.keys()
	for key:Variant in keys:
		if(!(key is PlayerAbility)):
			continue
		abilities[key].queue_free()
		if(!is_instance_valid(key)):
			abilities.erase(key)
			continue
		abilities[key]=make_ability_entry(key)

func make_ability_entry(ability:PlayerAbility)->Control:
	if(ability is CooldownAbility):
		var cdm:Control = preload("res://ui/cooldown_meter.tscn").instantiate()
		ability_list.add_child(cdm)
		cdm.ability = ability
		if(include_controls_in_abilities):
			cdm.text = UIUtil.get_controls_string(ability.mod_name)
			cdm.text += ' ' + ability.ability_name
		else:
			cdm.text = ability.ability_name
		
		return cdm
	else:
		var lbl:Label = Label.new()
		if(include_controls_in_abilities):
			lbl.text =  '[Passive] ' + ability.ability_name
		else:
			lbl.text = ability.ability_name
		ability_list.add_child(lbl)
		return lbl

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_score()
	update_health()
	update_abilities()
	if(!Engine.is_editor_hint()):
		var player:Player = get_tree().get_first_node_in_group('Players')
		if(is_instance_valid(player)):
			player.score_changed.connect(_on_player_score_changed)
			_on_player_score_changed(player.score)
			player.child_entered_tree.connect(_on_player_child_added)
			for child:Node in player.get_children():
				_on_player_child_added(child)
			player.child_exiting_tree.connect(_on_player_child_removed)
			player.health_changed.connect(_on_player_health_changed)
			_on_player_health_changed(player.health,player.max_health)


func _on_player_score_changed(to:float)->void:
	score=to

func _on_player_child_added(child:Node)->void:
	if(child is PlayerAbility):
		abilities[child]=make_ability_entry(child)

func _on_player_child_removed(child:Node)->void:
	if(child is PlayerAbility && abilities.has(child)):
		abilities[child].queue_free()
		abilities.erase(child)

func _on_player_health_changed(current:float, maximum:float)->void:
	max_health = maximum
	health = current
