extends Node

## Pickup types to spawn. Each scene's root must have a script extending the Pickup class.
@export var pickup_list:Array[PackedScene]

## The extra points from a spawn event that couldn't be used to spawn anything.
var leftover:float = 0

# contains : {packed_scene:value}
var spawn_list:Dictionary
var total_weight_in_list:float
var min_value:float

func _ready()->void:
	Actor.something_died.connect(_on_something_died)
	spawn_list = {}
	total_weight_in_list = 0
	min_value = INF
	for scene:PackedScene in pickup_list:
		var pickup:Pickup = scene.instantiate()
		min_value = min(pickup.value,min_value)
		var weight:float = 1 / pickup.value
		pickup.queue_free()
		spawn_list[scene] = pickup.value
		total_weight_in_list += weight

func _on_something_died(damage:Damage)->void:
	if(damage.attacker is Player && damage.target is Enemy):
	
		var total = randf() * damage.target.point_value * (abs(randfn(1,1))+1)
		
		while(total>min_value):
			# pick a random scene from spawn list, weighted by value
			var choice:float = randf() * total_weight_in_list
			var chosen_scene:PackedScene
			while(choice>0):
				for scene:PackedScene in spawn_list:
					if(spawn_list[scene]>total):
						continue
					choice -= 1/spawn_list[scene]
					if(choice<=0):
						chosen_scene=scene
						break
			var pickup:Pickup = chosen_scene.instantiate()
			pickup.position = damage.target.position
			pickup.velocity = Vector2(randfn(0,20),randfn(0,20)) + damage.target.linear_velocity
			pickup.target = damage.attacker
			add_child(pickup)
			total-=pickup.value
		
		leftover = total
