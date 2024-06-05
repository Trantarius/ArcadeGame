extends Area2D

## Size of the resulting explosion
@export var explosion_radius:float = 256
## Damage of the resulting explosion
@export var explosion_damage:float = 50

## Time until deletion
@export var lifetime:float = 10

@export_flags_2d_physics var explosion_mask:int

var linear_velocity:Vector2
var angular_velocity:float

var lifetime_timer:CountdownTimer = CountdownTimer.new()
var enemies_detected:int = 0
var source:Actor

func _ready() -> void:
	lifetime_timer.time = lifetime
			
func _physics_process(delta: float) -> void:
	
	modulate.a = clamp(lifetime_timer.time,0,1)
	if(lifetime_timer.time <= 0):
		queue_free()

var _exploded:bool = false
func _on_body_entered(body: Node2D) -> void:
	if(!_exploded):
		_exploded=true
		var explosion:Explosion = Explosion.new()
		explosion.collision_mask = explosion_mask
		explosion.damage_amount = explosion_damage
		explosion.radius = explosion_radius
		explosion.position = global_position
		explosion.source = source
		get_tree().current_scene.add_child(explosion)
		queue_free()

func _on_missile_ai_pre_update() -> void:
	$MissileAI.global_transform = global_transform
	$MissileAI.linear_velocity = linear_velocity
	$MissileAI.angular_velocity = angular_velocity
	$ArcDetector.update_detected()
	if($ArcDetector.detected.is_empty()):
		$MissileAI.target_position = global_position + Vector2.from_angle(global_rotation)*100
	else:
		if(is_instance_valid($ArcDetector.detected.keys()[0])):
			$MissileAI.target_position = $ArcDetector.detected.keys()[0].global_position
		else:
			$MissileAI.target_position = global_position + Vector2.from_angle(global_rotation)*100

func _on_missile_ai_post_update() -> void:
	global_transform = $MissileAI.global_transform
	linear_velocity = $MissileAI.linear_velocity
	angular_velocity = $MissileAI.angular_velocity
