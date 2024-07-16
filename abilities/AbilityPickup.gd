class_name AbilityPickup
extends Pickup

@export var ability_scene:PackedScene

func _on_picked_up(player: Player) -> void:
	var ability:PlayerAbility = ability_scene.instantiate()
	player.add_ability(ability)
