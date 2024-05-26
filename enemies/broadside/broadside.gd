extends Enemy

@export var cannon_fire_delay:float = 5
var port_fire_timer:CountdownTimer = CountdownTimer.new()
var starboard_fire_timer:CountdownTimer = CountdownTimer.new()

## The amount of force used to damp velocity perpendicular to the ship.
const keel_force:float = 10

## The amount of force used in the direction parallel to the ship to move it.
const thrust_force:float = 100

## Desired distance from the player.
const desired_distance:float = 500


func _ready() -> void:
	max_health = 0
	for child:Node in ($Port/Turrets.get_children() + $Port/Cannons.get_children() + 
					   $Starboard/Turrets.get_children() + $Starboard/Cannons.get_children() +
					   [$Engine, $Engine2]):
		$'.'.add_collision_exception_with(child)
		child.add_collision_exception_with(self)
		child.damage_taken.connect(_on_part_damaged, CONNECT_DEFERRED)
		max_health += child.max_health

func _on_part_damaged(damage:Damage)->void:
	damage.silent=true
	take_damage(damage)

func _physics_process(_delta: float) -> void:
	
	if(port_fire_timer.time<=0):
		var fire_port:bool = false
		for cannon:Enemy in $Port/Cannons.get_children():
			if(!cannon.get_node(^'Detector').get_overlapping_bodies().is_empty()):
				fire_port=true
				break
		if(fire_port):
			for cannon:Enemy in $Port/Cannons.get_children():
				cannon.fire()
			port_fire_timer.time = cannon_fire_delay
	
	if(starboard_fire_timer.time<=0):
		var fire_starboard:bool = false
		for cannon:Enemy in $Starboard/Cannons.get_children():
			if(!cannon.get_node(^'Detector').get_overlapping_bodies().is_empty()):
				fire_starboard=true
				break
		if(fire_starboard):
			for cannon:Enemy in $Starboard/Cannons.get_children():
				cannon.fire()
			starboard_fire_timer.time = cannon_fire_delay
	
	var keel_dir:Vector2 = Vector2.from_angle(global_rotation).orthogonal()
	var keel_vel:float = self.linear_velocity.dot(keel_dir)
	var keel_imp:Vector2 = -tanh(keel_vel) * keel_dir * keel_force
	$'.'.apply_central_force(keel_imp)
	
	var target:Player = Player.find_nearest_player(global_position)
	if(is_instance_valid(target)):
		
		var current_perp_dist:float = (target.global_position - global_position).dot(keel_dir)
