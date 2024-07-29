class_name StatBuffStack
extends Node

@export var buff:StatBuff

func _on_player_new_ability(ability:PlayerAbility)->void:
	if(ability.type==buff.target && buff.stat_name in ability && ability.get(buff.stat_name) is Stat):
		ability.get(buff.stat_name).add_buff(buff)
		tree_exiting.connect(ability.get(buff.stat_name).remove_buff.bind(buff),CONNECT_ONE_SHOT)

func _enter_tree() -> void:
	var node:Node = get_parent()
	while(is_instance_valid(node)):
		match buff.target:
			StatBuff.PARENT:
				if(buff.stat_name in node && node.get(buff.stat_name) is Stat):
					node.get(buff.stat_name).add_buff(buff)
					tree_exiting.connect(node.get(buff.stat_name).remove_buff.bind(buff), CONNECT_ONE_SHOT)
					break
				else:
					node = node.get_parent()
			
			StatBuff.WEAPON, StatBuff.MOVEMENT_ABILITY, StatBuff.ATTACK_ABILITY:
				if(node is Player):
					if(node.abilities.has(buff.target) && buff.stat_name in node.abilities[buff.target] && node.abilities[buff.target].get(buff.stat_name) is Stat):
						var stat:Stat = node.abilities[buff.target].get(buff.stat_name)
						stat.add_buff(buff)
						tree_exiting.connect(stat.remove_buff.bind(buff), CONNECT_ONE_SHOT)
					node.new_ability.connect(_on_player_new_ability)
					break
				else:
					node = node.get_parent()
