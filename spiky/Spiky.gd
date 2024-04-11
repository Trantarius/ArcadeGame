class_name Spiky
extends Enemy


func _physics_process(delta: float) -> void:
	
	var move_dir:Vector2
	var target:Player = find_nearest_player()
	if(target==null):
		if(velocity==Vector2.ZERO):
			move_dir=Vector2.ZERO
		else:
			move_dir=-velocity.normalized()
	else:
		move_dir=(target.position-position).normalized()
	
	if(move_dir!=Vector2.ZERO):
		rotate(sin(move_dir.angle_to(velocity)) * rotation_speed * delta)
	velocity += move_dir * acceleration * delta
	
	super(delta)
