class_name Modifier
extends Node

## If another modifier with this name already exists, this will replace it or stack with it.
## For active abilities, this is the name of the InputAction to activate it.
@export var mod_name:StringName
## Allows multiple modifiers of the same name to be added, incrementing [member stacks].
@export var stackable:bool = false
## Number of copies this node represents
var stacks:int = 1
