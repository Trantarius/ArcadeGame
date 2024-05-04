class_name PlayerAbility
extends Node

## Display name of the ability.
@export var ability_name:StringName

## Time before ability can be used again in seconds.
@export var cooldown:float

enum{PASSIVE=0,MOVEMENT=1,ATTACK=2}
## The type of the ability. Determines the equip slot and use key.
@export_enum("Passive:0","Movement:1","Attack:2") var equip_type:int

## Sent when the player uses the ability with the relevant key.
signal activate
