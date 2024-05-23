extends Enemy

@export var cannon_fire_delay:float = 5
var port_fire_timer:CountdownTimer = CountdownTimer.new()
var starboard_fire_timer:CountdownTimer = CountdownTimer.new()

func _ready() -> void:
	max_health = 0
	for child:Node in get_children():
		if(child.is_in_group(&'BroadsidePart')):
			$'.'.add_collision_exception_with(child)
			child.add_collision_exception_with(self)
			child.damage_taken.connect(_on_part_damaged, CONNECT_DEFERRED)
			max_health += child.max_health

func _on_part_damaged(damage:Damage)->void:
	damage.silent=true
	take_damage(damage)

func _physics_process(_delta: float) -> void:
	if(!$PortCannonDetector.get_overlapping_bodies().is_empty() && port_fire_timer.time<=0):
		if(has_node(^'Cannon')):
			$Cannon.fire()
		if(has_node(^'Cannon2')):
			$Cannon2.fire()
		if(has_node(^'Cannon3')):
			$Cannon3.fire()
		if(has_node(^'Cannon4')):
			$Cannon4.fire()
		if(has_node(^'Cannon5')):
			$Cannon5.fire()
		if(has_node(^'Cannon6')):
			$Cannon6.fire()
		port_fire_timer.time = cannon_fire_delay 
	if(!$StarboardCannonDetector.get_overlapping_bodies().is_empty() && starboard_fire_timer.time<=0):
		if(has_node(^'Cannon7')):
			$Cannon7.fire()
		if(has_node(^'Cannon8')):
			$Cannon8.fire()
		if(has_node(^'Cannon9')):
			$Cannon9.fire()
		if(has_node(^'Cannon10')):
			$Cannon10.fire()
		if(has_node(^'Cannon11')):
			$Cannon11.fire()
		if(has_node(^'Cannon12')):
			$Cannon12.fire()
		starboard_fire_timer.time = cannon_fire_delay 
