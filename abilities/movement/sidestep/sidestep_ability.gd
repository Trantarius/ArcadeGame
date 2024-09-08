extends CooldownAbility

const step_distance:float = 100

func _on_triggered()->void:
	var player:Player = get_parent()
	var hdir:float = Input.get_axis('left','right')
	if(hdir==0):
		hdir = 1 if randf()<0.5 else -1
	var dir = hdir * Vector2.RIGHT.rotated(player.rotation)
	player.move_and_collide(dir*step_distance)
