class_name StatBuff
extends Resource

@export var name:StringName

# must match the values of the same name in Stat.gd
@export_enum('Pre-Add:0','Mul:1','Add:2','Post-Mul:3') var stage:int

@export var strength:float
@export var stat_name:StringName

# must match the values found in PlayerAbility.gd
enum{PARENT=3,WEAPON=2,MOVEMENT_ABILITY=0,ATTACK_ABILITY=1}
@export_enum('Parent:3','Weapon:2','Movement Ability:0','Attack Ability:1') var target:int
