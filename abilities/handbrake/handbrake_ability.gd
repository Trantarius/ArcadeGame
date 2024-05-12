extends CooldownAbility

func _activate() -> void:
	get_parent().linear_velocity = Vector2.ZERO
