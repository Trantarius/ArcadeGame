class_name PickupSpawner
extends Node

## Multiplies the amount of drops from every random drop event.
@export var global_drop_rate_multiplier:float = 1

## Toggles all drops
@export var enabled:bool = true

func _ready()->void:
	Actor.something_died.connect(_on_something_died)

func _on_something_died(damage:Damage)->void:
	if(!enabled):
		return
	if(damage.attacker is Player && damage.target is Enemy && randf()<0.1):
		
		var health_pickup:Pickup = preload("res://pickups/health_pickup.tscn").instantiate()
		drop(health_pickup,damage.target)

func drop(pickup:Pickup, actor:Actor)->void:
	if(!enabled):
		pickup.queue_free()
		return
	var radius:float = actor.radius
	var position:Vector2 = actor.global_position
	var velocity:Vector2 = actor.get_average_velocity()
	
	var tform:Transform2D = Transform2D(0,Vector2.from_angle(randf()*TAU)*sqrt(randf())*radius + position)
	var attempts:int = 1
	while(!Util.does_node_fit(pickup,tform)):
		if(attempts%10==0):
			await get_tree().process_frame
		tform = Transform2D(0,Vector2.from_angle(randf()*TAU)*sqrt(randf())*radius + position)
		attempts += 1
	if(attempts>10):
		push_warning('drop took '+str(attempts)+' attempts to place')
	pickup.transform = tform
	add_child.call_deferred(pickup)
	pickup.linear_velocity = velocity/2 + Vector2(randfn(0,20),randfn(0,20))
