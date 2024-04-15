class_name Player
extends Actor

## Bullets shot per second while holding the 'shoot' button
@export var fire_rate:float
## Time until the next shot can be taken
var shot_timer:float

func _ready()->void:
	# ensure camera stays around after player dies
	death.connect(func()->void:
		$Camera2D.reparent(get_parent()))

func _physics_process(delta: float) -> void:
	
	# since 'left' and 'right' are buttons, this will always be -1, 0, or 1
	var rotation_input:float = Input.get_axis('left','right')
	angular_target = rotation_input * max_angular_speed
	
	if(Input.is_action_pressed('forward')):
		linear_target = global_transform.basis_xform(Vector2.UP).normalized() * max_linear_thrust
	else:
		linear_target = Vector2.ZERO
	
	shot_timer-=delta
	if(Input.is_action_pressed('shoot') && shot_timer<=0):
		fire_bullet()
		shot_timer = 1.0/fire_rate

func fire_bullet()->void:
	var bullet:Projectile = preload("res://bullet.tscn").instantiate()
	bullet.position = position
	bullet.velocity = 500 * global_transform.basis_xform(Vector2.UP).normalized() + linear_velocity
	# enable collision with enemies
	bullet.collision_mask|=0b100
	bullet.modulate=Color(0.5,0.5,1)
	bullet.source=self
	get_parent().add_child(bullet)
