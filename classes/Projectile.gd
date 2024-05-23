class_name Projectile
extends Area2D

## How long after firing the projectile is destroyed
@export var lifetime:float = 10
var lifetime_timer:CountdownTimer = CountdownTimer.new()

@export var damage_amount:float = 1

var source:Actor
var linear_velocity:Vector2
var angular_velocity:float

signal damage_dealt(damage:Damage)

func _init()->void:
	area_shape_entered.connect(_projectile_area_shape_entered)
	body_entered.connect(_projectile_body_entered)

func _ready()->void:
	lifetime_timer.time = lifetime

func _physics_process(delta: float) -> void:
	
	modulate.a = clamp(lifetime_timer.time,0,1)
	if(lifetime_timer.time <= 0):
		queue_free()
	
	global_rotation += angular_velocity * delta
	global_position += linear_velocity * delta

var _projectile_has_hit:bool = false

func _projectile_area_shape_entered(area_rid:RID, area:Area2D, area_shape_index:int, local_shape_index:int)->void:
	if(area is HitBox && !_projectile_has_hit):
		if(area.actor.health<=0):
			return
		
		var contact:Dictionary = Util.collider_get_shape_contact(self, local_shape_index, area, area_shape_index)
		
		var damage:Damage = Damage.new()
		damage.amount = damage_amount
		damage.attacker = source
		damage.target = area.actor
		if(contact.is_empty()):
			damage.position = (area.global_position + global_position)/2
			damage.direction = (area.global_position - global_position).normalized()
		else:
			damage.position = contact.position
			damage.direction = contact.normal
		damage_dealt.emit(damage)
		damage.target.take_damage(damage)
		
		_projectile_has_hit=true
		
		queue_free()

func _projectile_body_entered(body:Node2D)->void:
	queue_free()
