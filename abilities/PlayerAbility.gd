class_name PlayerAbility
extends Modifier

## Display name of the ability.
@export var ability_name:StringName

## Texture of the ability pickup/card.
@export var texture:Texture2D

## Displayed type of the ability.
@export_enum("Passive","Movement","Attack","Weapon")
var type:String

## Description of the ability for the ability card.
@export_multiline var description:String

func _enter_tree()->void:
	is_active = get_parent() is Player

func _exit_tree() -> void:
	is_active = false
