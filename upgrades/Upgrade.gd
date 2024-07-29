class_name Upgrade
extends Node

@export var upgrade_name:StringName
enum{COMMON=0,RARE=1}
@export_enum('Common:0','Rare:1') var rarity:int = COMMON
@export_multiline var description:String
