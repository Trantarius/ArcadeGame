extends Node

## Multiplies the amount of drops from every drop event.
@export var global_drop_rate_multiplier:float = 1

## Pickup types to spawn. Each scene's root must have a script extending the Pickup class.
@export var pickup_list:Array[PackedScene]

## Toggles all drops
@export var enabled:bool = true

## Extra points that couldn't produce drops in the last event
var leftover:float
## Internal list of everything that can spawn. Format is 
## [code]{StringName:{'scene':PackedScene,'value':float}}[/code]
var spawn_list:Dictionary

func _ready()->void:
	Actor.something_died.connect(_on_something_died)
	for scene:PackedScene in pickup_list:
		var pickup:Pickup = scene.instantiate()
		spawn_list[StringName(pickup.name)]={'scene':scene,'value':pickup.value}
		pickup.queue_free()

func _on_something_died(damage:Damage)->void:
	if(!enabled):
		return
	if(damage.attacker is Player && damage.target is Enemy):
	
		var total_value:float = damage.target.point_value * 2**(randfn(0,1)) * global_drop_rate_multiplier
		drop_event(total_value,damage.target.radius,damage.target.position,damage.target.get_average_velocity())

func drop_event(total_value:float, radius:float, position:Vector2, velocity:Vector2)->void:
	total_value += leftover
	var list:Array = spawn_list.keys().duplicate()
	while(!list.is_empty()):
		var chosen_idx:int = randi()%list.size()
		var chosen:StringName = list[chosen_idx]
		while(spawn_list[chosen].value > total_value):
			#list.erase(chosen)
			list.remove_at(chosen_idx)
			if(list.is_empty()):
				break
			chosen_idx = randi()%list.size()
			chosen = list[chosen_idx]
		if(list.is_empty()):
			break
		var pickup:Pickup = spawn_list[chosen].scene.instantiate()
		var locator:Callable = func()->Transform2D:
			return Transform2D(0,Vector2.from_angle(randf()*TAU)*sqrt(randf())*radius + position)
		if(!Util.attempt_place_body(pickup,self,locator,5)):
			push_error("Failed to place a pickup after 5 attempts")
			pickup.queue_free()
			leftover=total_value
			return
		pickup.linear_velocity = Vector2(randfn(0,20),randfn(0,20)) + velocity
		total_value-=pickup.value
	leftover = total_value
