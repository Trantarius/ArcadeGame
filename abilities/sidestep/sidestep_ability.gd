extends CooldownAbility

const step_distance:float = 100

func _trigger()->void:
	var player:Player = get_parent()
	var hdir:float = Input.get_axis('left','right')
	var dir = hdir * Vector2.RIGHT.rotated(player.rotation)
	player.slide_warp(dir*step_distance)
