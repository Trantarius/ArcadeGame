extends Area2D

## Size of the resulting explosion
var explosion_radius:float = 128
## Damage of the resulting explosion
var explosion_damage:float = 10

## Time until deletion
@export var lifetime:float = 10

@export_flags_2d_physics var explosion_mask:int

const max_speed:float = 1000
const max_rot_speed:float = 10
const max_thrust:float = 200

var linear_velocity:Vector2
var angular_velocity:float

@onready var lifetime_timer:ReversibleTimer = $LifetimeTimer
var enemies_detected:int = 0
var source:Actor

func _ready() -> void:
	lifetime_timer.duration = lifetime
	lifetime_timer.reset()
	lifetime_timer.start()
			
func _physics_process(delta: float) -> void:
	
	modulate.a = clamp(lifetime_timer.time,0,1)
	if(lifetime_timer.is_finished()):
		queue_free()
	
	var facing:Vector2 = Vector2.from_angle(global_rotation)
	linear_velocity = linear_velocity.project(facing) + linear_velocity.project(facing.orthogonal())*(1-get_physics_process_delta_time()*4)
	linear_velocity += facing * max_thrust * get_physics_process_delta_time()
	linear_velocity = linear_velocity.limit_length(max_speed)
	
	var det:Array = $ArcDetector.detected.keys()
	if(!det.is_empty()):
		var target:Node2D = det[0]
		
		var to_target:Vector2 = target.global_position - global_position
		var facing_to_target:Vector2 = Vector2.from_angle(global_rotation-to_target.angle())
		if(facing.dot(to_target)<0):
			angular_velocity = sign(angle_difference(global_rotation,to_target.angle())) * max_rot_speed
		elif(is_equal_approx(0,facing_to_target.y)):
			angular_velocity=0
		else:
			var rot_center:Vector2 = (global_position+target.global_position + to_target.orthogonal()*facing_to_target.x/facing_to_target.y)/2
			angular_velocity = -sign((rot_center-global_position).dot(facing.orthogonal())) * linear_velocity.length()/(rot_center-global_position).length()
		
		angular_velocity = clamp(angular_velocity*2, -max_rot_speed, max_rot_speed)
	
	global_position += linear_velocity * delta
	global_rotation += angular_velocity * delta

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
