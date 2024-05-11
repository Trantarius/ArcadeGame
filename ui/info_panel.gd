@tool
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

@export var abilities:Array[PlayerAbility]:
	set(to):
		abilities=to
		if(is_inside_tree()):
			update_abilities()

func update_abilities()->void:
	for child:Node in ability_list.get_children():
		child.queue_free()
	
	if(include_basic_controls_in_abilities && include_controls_in_abilities):
		add_ability_entry(get_controls_string(&'left')+' '+get_controls_string(&'right')+' Rotate')
		add_ability_entry(get_controls_string(&'forward')+' Thrust')

	for ability:PlayerAbility in abilities:
		if(is_instance_valid(ability)):
			add_ability_entry(get_ability_string(ability))

func add_ability_entry(entry:String)->void:
	var lbl:Label = Label.new()
	lbl.text = entry
	ability_list.add_child(lbl)

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
		abilities.push_back(child)

func _on_player_child_removed(child:Node)->void:
	if(child is PlayerAbility):
		abilities.erase(child)

func _on_player_health_changed(current:float, maximum:float)->void:
	max_health = maximum
	health = current

func get_ability_string(ability:PlayerAbility)->String:
	if(include_controls_in_abilities):
		var ret:String
		match ability.equip_type:
			PlayerAbility.PASSIVE:
				ret = '[Passive]'
			PlayerAbility.MOVEMENT:
				ret = get_controls_string(&'movement_ability')
			PlayerAbility.ATTACK:
				ret = get_controls_string(&'attack_ability')
		
		ret += ' ' + ability.ability_name
		return ret
	else:
		return ability.ability_name

func get_controls_string(action:StringName)->String:
	var ret:String
	var events:Array[InputEvent] = InputMap.action_get_events(action)
	if(events.is_empty()):
		ret = '[]'
	else:
		ret = '['
		ret += events[0].as_text().trim_suffix(' (Physical)')
		for i:int in range(1,events.size()):
			ret += '|' + events[i].as_text().trim_suffix(' (Physical)')
		ret += ']'
	return ret
