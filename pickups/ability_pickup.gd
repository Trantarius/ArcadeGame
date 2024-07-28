extends Pickup

@export var ability_scene:PackedScene:
	set(to):
		ability_scene = to
		$Interpolator/TextureRect.texture = Util.get_scene_prop(ability_scene, &'texture', preload('res://icon.svg'))

func _on_picked_up(player: Player) -> void:
	var ability:PlayerAbility = ability_scene.instantiate()
	player.add_ability(ability)
