class_name AbilityPickup
extends Pickup

# must match values found in PlayerAbility
@export_enum("Movement:0","Attack:1","Weapon:2") var type:int:
	set(to):
		type=to
		match type:
			PlayerAbility.MOVEMENT:
				$Interpolator/TextureRect.texture = preload('res://pickups/movement.png')
			PlayerAbility.ATTACK:
				$Interpolator/TextureRect.texture = preload('res://pickups/attack.png')
			PlayerAbility.WEAPON:
				$Interpolator/TextureRect.texture = preload('res://pickups/weapon.png')

const ability_lists:Dictionary = {
	PlayerAbility.MOVEMENT: preload("res://abilities/movement/movement_ability_list.tres"),
	PlayerAbility.ATTACK: preload("res://abilities/attack/attack_ability_list.tres"),
	PlayerAbility.WEAPON: preload("res://abilities/weapon/weapon_list.tres")
}

func _on_picked_up(player: Player) -> void:
	var ab_scene:PackedScene = ability_lists[type].pick_random()
	var ab_name:StringName = Util.get_scene_prop(ab_scene,&'ability_name')
	if(player.abilities.has(type) && player.abilities[type].ability_name==ab_name):
		while(player.abilities[type].ability_name == ab_name):
			ab_scene = ability_lists[type].pick_random()
			ab_name = Util.get_scene_prop(ab_scene,&'ability_name')
	var ability:PlayerAbility = ab_scene.instantiate()
	player.add_ability(ability)
