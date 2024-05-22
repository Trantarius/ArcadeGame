extends CooldownAbility

const step_distance:float = 100

func _on_triggered()->void:
	var player:Player = get_parent()
	var hdir:float = Input.get_axis('left','right')
	var dir = hdir * Vector2.RIGHT.rotated(player.rotation)
	player.move_and_collide(dir*step_distance)
