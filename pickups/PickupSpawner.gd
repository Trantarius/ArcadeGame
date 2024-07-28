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
	if(damage.attacker is Player && damage.target is Enemy):
	
		var total_value:float = damage.target.point_value * 2**(randfn(0,1)) * global_drop_rate_multiplier
		var weighter:Callable = func(scene:PackedScene)->float:
			var value:float = Util.get_scene_prop(scene, &'value', 1)
			var diff:float = total_value-value
			return 1.0/(diff*diff+1.0) if value<total_value else 0
		
		while(total_value>0):
			var scene:PackedScene = preload('res://pickups/random_drop_list.tres').pick_random(weighter)
			if(!is_instance_valid(scene)):
				break
			var value:float = Util.get_scene_prop(scene, &'value', 1)
			total_value -= value
			drop(scene.instantiate(), damage.target)

func drop(pickup:Pickup, actor:Actor)->void:
	if(!enabled):
		pickup.queue_free()
		return
	var radius:float = actor.radius
	var position:Vector2 = actor.global_position
	var velocity:Vector2 = actor.get_average_velocity()
	var locator:Callable = func()->Transform2D:
		return Transform2D(0,Vector2.from_angle(randf()*TAU)*sqrt(randf())*radius + position)
	if(!Util.attempt_place_node(pickup,self,locator,5)):
			push_error("Failed to place a pickup after 5 attempts")
			pickup.queue_free()
			return
	pickup.linear_velocity = velocity + (pickup.global_position-position)*3
