extends Pickup

## Amount of health to recover.
@export var health:float = 1

func _on_picked_up(player:Player)->void:
	player.health += health
