class_name Modifier
extends Node

## If another modifier with this name already exists, this will replace it or stack with it.
## For active abilities, this is the name of the InputAction to activate it.
@export var mod_name:StringName
## Allows multiple modifiers of the same name to be added, incrementing [member stacks].
@export var stackable:bool = false
## Number of copies this node represents.
var stacks:int = 1
## Whether or not the ability is currently applied to an actor.
var is_active:bool = false:
	set(to):
		if(is_active!=to):
			is_active=to
			if(is_active):
				_activate()
				activated.emit()
			else:
				_deactivate()
				deactivated.emit()

signal activated
func _activate()->void:
	pass

signal deactivated
func _deactivate()->void:
	pass

func _enter_tree()->void:
	is_active = get_parent() is Actor

func _exit_tree() -> void:
	is_active = false
