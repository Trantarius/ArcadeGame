class_name SoundMod
extends Node

var sound:SoundStack

func begin()->void:
	if(get_parent() is SoundStack):
		sound = get_parent()

func sample(time:float, idx:int)->void:
	pass

func finish()->void:
	pass
