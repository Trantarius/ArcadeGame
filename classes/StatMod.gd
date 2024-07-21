## Applies a modifier to the parent actor when it enters the tree, and removes the modifier when it exits the tree.
## None of its exported properties should be changed while inside the tree.
class_name StatMod
extends Node

@export var mod_name:StringName

# must match the values of the same name in Stat.gd
@export_enum('Pre-Add:0','Mul:1','Add:2','Post-Mul:3') var stage:int

@export var strength:float
@export var stacks:int = 1
@export var stat_name:StringName

# must match the values found in PlayerAbility.gd
enum{PARENT=3,WEAPON=2,MOVEMENT_ABILITY=0,ATTACK_ABILITY=1}
@export_enum('Parent:3','Weapon:2','Movement Ability:0','Attack Ability:1') var target:int

func apply(obj:Object)->void:
	if(stat_name in obj && obj.get(stat_name) is Stat):
		obj.get(stat_name).add_mod(self)
		tree_exiting.connect(obj.get(stat_name).remove_mod.bind(self))

func _on_player_new_ability(ability:PlayerAbility)->void:
	if(ability.type==target && stat_name in ability && ability.get(stat_name) is Stat):
		ability.get(stat_name).add_mod(mod_name, stage, strength, stacks)
		tree_exiting.connect(ability.get(stat_name).remove_mod.bind(mod_name, stage, stacks))

func _enter_tree() -> void:
	var node:Node = get_parent()
	while(is_instance_valid(node)):
		match target:
			PARENT:
				if(stat_name in node && node.get(stat_name) is Stat):
					node.get(stat_name).add_mod(mod_name, stage, strength, stacks)
					tree_exiting.connect(node.get(stat_name).remove_mod.bind(mod_name,stage,stacks))
					break
				else:
					node = node.get_parent()
			
			WEAPON:
				if(node is Player):
					if(is_instance_valid(node.weapon) && stat_name in node.weapon && node.weapon.get(stat_name) is Stat):
						var stat:Stat = node.weapon.get(stat_name)
						stat.add_mod(mod_name, stage, strength, stacks)
						tree_exiting.connect(stat.remove_mod.bind(mod_name, stage, stacks))
					node.new_ability.connect(_on_player_new_ability)
					break
				else:
					node = node.get_parent()
			
			MOVEMENT_ABILITY:
				if(node is Player):
					if(is_instance_valid(node.movement_ability) && stat_name in node.movement_ability && node.movement_ability.get(stat_name) is Stat):
						var stat:Stat = node.movement_ability.get(stat_name)
						stat.add_mod(mod_name, stage, strength, stacks)
						tree_exiting.connect(stat.remove_mod.bind(mod_name, stage, stacks))
					break
				else:
					node = node.get_parent()
			
			ATTACK_ABILITY:
				if(node is Player):
					if(is_instance_valid(node.attack_ability) && stat_name in node.attack_ability && node.attack_ability.get(stat_name) is Stat):
						var stat:Stat = node.attack_ability.get(stat_name)
						stat.add_mod(mod_name, stage, strength, stacks)
						tree_exiting.connect(stat.remove_mod.bind(mod_name, stage, stacks))
					break
				else:
					node = node.get_parent()
