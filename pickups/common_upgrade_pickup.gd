extends Pickup

const list:SceneList = preload('res://upgrades/common_upgrade_list.tres')

func _on_picked_up(player: Player) -> void:
	player.add_upgrade([list.pick_random().instantiate(),list.pick_random().instantiate(),list.pick_random().instantiate()])
