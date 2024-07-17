class_name AbilityStatMod
extends Node

@export var stat_name:StringName
@export_enum('pre-add', 'mul', 'add', 'post-mul') var stage:String
@export var strength:float
@export_enum('Movement:0','Attack:1','Weapon:2') var ability_type:int

func _enter_tree() -> void:
	get_parent().new_ability.connect(_on_player_new_ability)
	if(get_parent().abilities.has(ability_type)):
		var ability:PlayerAbility = get_parent().abilities[ability_type]
		if(stat_name in ability && ability.get(stat_name) is Stat):
			match stage:
				'pre-add':
					ability.get(stat_name).pre_add_effects[name]=strength
				'mul':
					ability.get(stat_name).mul_effects[name]=strength
				'add':
					ability.get(stat_name).add_effects[name]=strength
				'post-mul':
					ability.get(stat_name).post_mul_effects[name]=strength

func _exit_tree() -> void:
	get_parent().new_ability.disconnect(_on_player_new_ability)
	if(get_parent().abilities.has(ability_type)):
		var ability:PlayerAbility = get_parent().abilities[ability_type]
		if(stat_name in ability && ability.get(stat_name) is Stat):
			match stage:
				'pre-add':
					ability.get(stat_name).pre_add_effects.erase(name)
				'mul':
					ability.get(stat_name).mul_effects.erase(name)
				'add':
					ability.get(stat_name).add_effects.erase(name)
				'post-mul':
					ability.get(stat_name).post_mul_effects.erase(name)
	

func _on_player_new_ability(ability:PlayerAbility)->void:
	if(ability.type==ability_type && stat_name in ability && ability.get(stat_name) is Stat):
		match stage:
			'pre-add':
				ability.get(stat_name).pre_add_effects[name]=strength
			'mul':
				ability.get(stat_name).mul_effects[name]=strength
			'add':
				ability.get(stat_name).add_effects[name]=strength
			'post-mul':
				ability.get(stat_name).post_mul_effects[name]=strength
