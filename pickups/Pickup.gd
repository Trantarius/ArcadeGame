class_name Pickup
extends Area2D

## Time until deletion.
@export var lifetime:float = 10
## How valuable this pickup is, effects drop rate (same unit as [member Enemy.point_value]).
@export var value:float = 1

var linear_velocity:Vector2
var angular_velocity:float

signal picked_up(player:Player)

func _init()->void:
	body_entered.connect(_pickup_on_body_entered)

func _physics_process(delta: float) -> void:
	var target:Player = Player.find_nearest_player(position)
	if(!is_instance_valid(target)):
		return
	position += linear_velocity * delta
	rotation += angular_velocity * delta
	if(is_instance_valid(target)):
		var currvel:Vector2 = linear_velocity - target.linear_velocity
		var wantvel:Vector2 = (target.position-position).normalized() * min(currvel.length()*1.5,(target.position-position).length()/delta)
		var dweight:float = (target.position-position).length()/target.pickup_magnet
		dweight = 1/(exp(dweight**2)-1)
		linear_velocity += (wantvel-currvel) * min(1,dweight*delta)
	lifetime -= delta
	modulate.a = min(1,lifetime)
	if(lifetime<0):
		queue_free()

func _pickup_on_body_entered(body:Node2D)->void:
	if(body is Player):
		picked_up.emit(body)
		queue_free()
