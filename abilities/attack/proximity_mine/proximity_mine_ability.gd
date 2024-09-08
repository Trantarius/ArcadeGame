extends CooldownAbility

## Damage dealt by the mine's explostion
@export var damage:Stat 
## Radius of the mine's explosion
@export var explosion_size:Stat 
## Time it takes to arm the mine after dropping
@export var arming_time:Stat 

func _on_triggered() -> void:
	var mine:Node2D = preload("res://abilities/attack/proximity_mine/mine.tscn").instantiate()
	mine.global_position = get_parent().global_position
	mine.linear_velocity = get_parent().linear_velocity - get_parent().linear_velocity.normalized()*50
	mine.attacker = get_parent()
	mine.source = self
	mine.explosion_damage = damage.get_value()
	mine.explosion_radius = explosion_size.get_value()
	mine.arming_time = arming_time.get_value()
	
	get_tree().current_scene.add_child(mine)
