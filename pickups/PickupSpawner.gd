extends Node

## Multiplies the amount of drops from every drop event.
@export var global_drop_rate_multiplier:float = 1

## Pickup types to spawn. Each scene's root must have a script extending the Pickup class.
@export var pickup_list:Array[PackedScene]

## Extra points that couldn't produce drops in the last event
var leftover:float

func _ready()->void:
	Actor.something_died.connect(_on_something_died)

func _on_something_died(damage:Damage)->void:
	if(damage.attacker is Player && damage.target is Enemy):
	
		var total:float = damage.target.point_value * 2**(randfn(0,1)) * global_drop_rate_multiplier + leftover
		var list:Array[PackedScene] = pickup_list.duplicate()
		while(!list.is_empty()):
			var chosen_scene:PackedScene = list.pick_random()
			var pickup:Pickup = chosen_scene.instantiate()
			while(pickup.value > total):
				pickup.queue_free()
				list.erase(chosen_scene)
				if(list.is_empty()):
					break
				chosen_scene = list.pick_random()
				pickup = chosen_scene.instantiate()
			if(list.is_empty()):
				pickup.queue_free()
				break
			pickup.position = damage.target.position
			pickup.linear_velocity = Vector2(randfn(0,20),randfn(0,20)) + damage.target.linear_velocity
			add_child(pickup)
			total-=pickup.value
		leftover = total
