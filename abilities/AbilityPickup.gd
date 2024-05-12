class_name AbilityPickup
extends Pickup

@export var ability_scene:PackedScene

func _on_picked_up(player: Player) -> void:
	player.add_modifier(ability_scene.instantiate())
