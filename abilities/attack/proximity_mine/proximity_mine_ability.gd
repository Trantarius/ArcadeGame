extends CooldownAbility

@export var damage:Stat # = Stat.new(50,0,INF)
@export var explosion_size:Stat # = Stat.new(256, 4, INF)
@export var arming_time:Stat # = Stat.new(3, 0, INF)

func _on_triggered() -> void:
	var mine:Node2D = preload("res://abilities/attack/proximity_mine/mine.tscn").instantiate()
	mine.global_position = get_parent().global_position
	mine.linear_velocity = get_parent().linear_velocity - get_parent().linear_velocity.normalized()*50
	mine.source = get_parent()
	mine.explosion_damage = damage.get_value()
	mine.explosion_radius = explosion_size.get_value()
	mine.arming_time = arming_time.get_value()
	
	get_tree().current_scene.add_child(mine)
