class_name Pickup
extends RigidBody2D

## How long to wait before deleting the pickup after spawning.
@export var lifetime:float = 10
## How valuable this pickup is, effects drop rate (same unit as [member Enemy.point_value]).
@export var value:float = 1

var lifetime_timer:Timer

signal picked_up(player:Player)

func _init()->void:
	contact_monitor=true
	max_contacts_reported=3
	physics_material_override = preload("res://pickups/pickup_physics_material.tres")
	lock_rotation = true
	add_to_group('Pickups')

func _ready()->void:
	lifetime_timer = Timer.new()
	lifetime_timer.name = 'LifetimeTimer'
	lifetime_timer.one_shot = true
	add_child(lifetime_timer)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start(lifetime)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var target:Player = Player.find_nearest_player(position)
	if(is_instance_valid(target)):
		var currvel:Vector2 = state.linear_velocity - target.linear_velocity
		var wantvel:Vector2 = (target.position-position).normalized() * min(currvel.length()*1.5,(target.position-position).length()/state.step)
		var dweight:float = (target.position-position).length()/target.pickup_magnet
		dweight = 1/(exp(dweight**2)-1)
		state.linear_velocity += (wantvel-currvel) * min(1,dweight*state.step)
	
	for c:int in state.get_contact_count():
		if(state.get_contact_collider_object(c) is Player):
			picked_up.emit(state.get_contact_collider_object(c))
			queue_free()
			break
	
	modulate.a = min(1,lifetime_timer.time_left)
