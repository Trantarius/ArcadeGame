extends CooldownAbility

const strength:float = 500

func _trigger() -> void:
	var player:Player = get_parent()
	var dir:Vector2 = Vector2.UP.rotated(player.global_rotation)
	var impulse:Vector2 = dir*strength
	var acc:Vector2 = impulse/player.mass
	
	acc += player.linear_velocity
	acc = acc.limit_length(player.max_linear_speed)
	acc -= player.linear_velocity
	
	player.apply_impulse(acc*player.mass)
