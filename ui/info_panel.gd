class_name InfoPanel
extends Control

@export var score_label:Label
@export var health_bar:HealthBar
@export var ability_list:VBoxContainer

@export var player:Player:
	set(to):
		if(is_instance_valid(player)):
			#player.score_changed.disconnect(_on_player_score_changed)
			player.health_changed.disconnect(health_bar._on_health_changed)
			player.added_ability.disconnect(_on_player_added_ability)
			player.removed_ability.disconnect(_on_player_removed_ability)
			for child:Node in ability_list.get_children():
				ability_list.remove_child(child)
			abilities.clear()
		player=to
		if(is_instance_valid(player)):
			#score_label.text = 'Score: %d'%[player.score]
			#player.score_changed.connect(_on_player_score_changed)
			health_bar.max_value = player.max_health.get_value()
			health_bar.value = player.health
			player.health_changed.connect(health_bar._on_health_changed)
			player.added_ability.connect(_on_player_added_ability)
			player.removed_ability.connect(_on_player_removed_ability)
			_add_controls()
			for ability:PlayerAbility in player.abilities.values():
				_on_player_added_ability(ability)

@export var run_monitor:RunMonitor:
	set(to):
		if(is_instance_valid(run_monitor)):
			run_monitor.score_changed.disconnect(_on_score_changed)
		run_monitor = to
		if(is_instance_valid(run_monitor)):
			run_monitor.score_changed.connect(_on_score_changed)

func _on_score_changed(to:float)->void:
	score_label.text = 'Score: %d'%[to]

var abilities:Dictionary

func _add_controls()->void:
	
	var rlbl:RichTextLabel = RichTextLabel.new()
	rlbl.bbcode_enabled = true
	rlbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rlbl.fit_content = true
	ability_list.add_child(rlbl)
	abilities[&'Rotate']=rlbl
	abilities[&'Rotate'].text = Util.get_controls_string(&'left')+' '+Util.get_controls_string(&'right')+' Rotate'
		
	var tlbl:RichTextLabel = RichTextLabel.new()
	tlbl.bbcode_enabled = true
	tlbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tlbl.fit_content = true
	ability_list.add_child(tlbl)
	abilities[&'Thrust']=tlbl
	abilities[&'Thrust'].text = Util.get_controls_string(&'forward')+' Thrust'

func make_ability_entry(ability:PlayerAbility)->Control:
	if(ability is CooldownAbility):
		var cdm:Control = preload("res://ui/cooldown_meter.tscn").instantiate()
		cdm.ability = ability
		cdm.text = Util.get_controls_string(ability.get_action_name())
		cdm.text += ' ' + ability.ability_name
		ability_list.add_child(cdm)
		return cdm
	else:
		var lbl:RichTextLabel = RichTextLabel.new()
		lbl.bbcode_enabled=true
		lbl.text =  '[lb]Passive[rb] ' + ability.ability_name
		ability_list.add_child(lbl)
		return lbl

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(!Engine.is_editor_hint() && !is_instance_valid(player)):
		player = get_tree().get_first_node_in_group('Players')

func _on_player_added_ability(ability:PlayerAbility)->void:
	abilities[ability]=make_ability_entry(ability)

func _on_player_removed_ability(ability:PlayerAbility)->void:
	if(abilities.has(ability)):
		abilities[ability].queue_free()
		abilities.erase(ability)
