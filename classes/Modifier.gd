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
				activated.emit()
			else:
				deactivated.emit()

signal activated
signal deactivated

func _enter_tree()->void:
	var parent:Node = get_parent()
	if(parent is Actor):
		if(parent.modifiers.has(mod_name)):
			var old:Modifier = parent.modifiers[mod_name]
			parent.remove_child(old)
			old.queue_free()
		parent.modifiers[mod_name] = self
		is_active = true
	else:
		is_active = false

func _exit_tree() -> void:
	var parent:Node = get_parent()
	if(parent is Actor):
		parent.modifiers.erase(mod_name)
	is_active = false
