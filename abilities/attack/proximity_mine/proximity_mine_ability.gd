extends CooldownAbility


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_triggered() -> void:
	var mine:Node2D = preload("res://abilities/attack/proximity_mine/mine.tscn").instantiate()
	mine.global_position = get_parent().global_position
	mine.linear_velocity = get_parent().linear_velocity - get_parent().linear_velocity.normalized()*50
	
	get_parent().get_parent().add_child(mine)
