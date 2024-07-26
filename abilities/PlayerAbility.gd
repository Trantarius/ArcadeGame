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

# indicates if this ability is being added via Player.add_ability, or some other method
var ability_initialized:bool = false

func _enter_tree()->void:
	var parent:Node = get_parent()
	assert(parent is Player)
	if(!ability_initialized):
		# hasn't been added by Player.add_ability, needs to initialize itself
		parent.new_ability.emit(self)
		if(parent.abilities.has(type)):
			parent.remove_ability(parent.abilities[type])
		parent.abilities[type]=self
		parent.added_ability.emit(self)
		

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
