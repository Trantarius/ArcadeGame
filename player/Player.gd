class_name Player
extends Actor

## Bullets shot per second while holding the 'shoot' button
@export var fire_rate:float
## Allows for continuous shooting without holding the 'shoot' button
@export var auto_fire:bool
## Time until the next shot can be taken
var shot_timer:float
## Total value of all enemies this player has killed
var score:float

func _ready()->void:
	death.connect(_on_death)
	kill.connect(_on_kill)

func _on_death(damage:Damage)->void:
	# ensure camera stays around after player dies
	$Camera2D.velocity=linear_velocity
	$Camera2D.is_free=true
	$Camera2D.reparent(get_parent())

func _on_kill(damage:Damage)->void:
	if(damage.target is Enemy):
		score += damage.target.point_value

func _physics_process(delta: float) -> void:
	
	# since 'left' and 'right' are buttons, this will always be -1, 0, or 1
	var rotation_input:float = Input.get_axis('left','right')
	angular_target = rotation_input * max_angular_speed
	
	if(Input.is_action_pressed('forward')):
		linear_target = global_transform.basis_xform(Vector2.UP).normalized() * max_linear_thrust
	else:
		linear_target = Vector2.ZERO
	
	shot_timer-=delta
	if((Input.is_action_pressed('shoot')!=auto_fire) && shot_timer<=0):
		fire_bullet()
		shot_timer = 1.0/fire_rate

func fire_bullet()->void:
	var bullet:Projectile = preload("res://player/bullet.tscn").instantiate()
	bullet.position = position
	bullet.velocity = 800 * global_transform.basis_xform(Vector2.UP).normalized() + linear_velocity
	bullet.source=self
	get_parent().add_child(bullet)
