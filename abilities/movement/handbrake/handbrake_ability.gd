extends CooldownAbility

func _on_triggered() -> void:
	get_parent().linear_velocity = Vector2.ZERO
	get_parent().angular_velocity = 0
