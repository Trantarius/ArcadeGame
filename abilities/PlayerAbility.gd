class_name PlayerAbility
extends Node

## Display name of the ability.
@export var ability_name:StringName

## Texture of the ability pickup/card.
@export var texture:Texture2D

enum{MOVEMENT=0,ATTACK=1,WEAPON=2}

## Displayed type of the ability.
@export_enum("Movement:0","Attack:1","Weapon:2") var type:int

## Description of the ability for the ability card.
@export_multiline var description:String

static var _is_choosing_ability:bool = false
static var _ability_choice_done:Signal
static func _static_init() -> void:
	(PlayerAbility as Object).add_user_signal('_ability_choice_done')
	_ability_choice_done = Signal(PlayerAbility,'_ability_choice_done')

func _enter_tree()->void:
	var player:Player = get_parent()
	# wait until other selections are done
	while(_is_choosing_ability):
		await _ability_choice_done
	
	_is_choosing_ability = true
	player.new_ability.emit(self)
	
	if(player.abilities.has(type)):
		var other:PlayerAbility = player.abilities[type]
		if(other.ability_name == ability_name):
			# if the new ability is the same as the existing one, ignore it
			queue_free()
		else:
			var chooser:Control = load('res://ui/ability_choice_screen.tscn').instantiate()
			chooser.left_ability = other
			chooser.right_ability = self
			var uilayer:CanvasLayer = get_tree().get_first_node_in_group('UILayer')
			uilayer.add_child(chooser)
			var selected:PlayerAbility = await chooser.select_finished
			if(selected==self):
				player.removed_ability.emit(other)
				other.queue_free()
				player.abilities[type]=self
				player.added_ability.emit(self)
			else:
				queue_free()
	else:
		player.abilities[type]=self
		player.added_ability.emit(self)
	
	_is_choosing_ability = false
	_ability_choice_done.emit()

func get_action_name()->StringName:
	match type:
		MOVEMENT:
			return &'movement_ability'
		ATTACK:
			return &'attack_ability'
		_:
			return &''

func get_type_name()->String:
	match type:
		MOVEMENT:
			return 'Movement'
		ATTACK:
			return 'Attack'
		WEAPON:
			return 'Weapon'
		_:
			return ''
