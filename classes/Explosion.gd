@tool
class_name Explosion
extends Node2D

## Radius of explosion.
@export var radius:float:
	set(to):
		radius=to
		queue_redraw()

@export var damage_amount:float
@export var damage_silent:bool = false

@export_flags_2d_physics var collision_mask:int

var source:Actor
var duration:float
var timer:CountdownTimer = CountdownTimer.new()
## The velocity of the thing that created the explosion
var linear_velocity:Vector2

signal damage_dealt(damage:Damage)

func _ready()->void:
	material = preload("res://visual_effects/explosion_material.tres")
	duration = (material.get_shader_parameter('diffusion_time') + material.get_shader_parameter('activation_time'))
	if(Engine.is_editor_hint()):
		material.set_shader_parameter('current_time',-1)
	else:
		timer.time = duration
		
		var query:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.collision_mask = collision_mask
		query.shape = CircleShape2D.new()
		query.shape.radius = radius
		query.transform = global_transform
		var results:Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query,256)
		
		for res:Dictionary in results:
			if(res.collider is Actor):
				var damage:Damage = Damage.new()
				damage.amount = damage_amount
				damage.source = self
				damage.attacker = source
				damage.target = res.collider
				
				var shape_owner:int = res.collider.shape_find_owner(res.shape)
				var shape:Shape2D = res.collider.shape_owner_get_shape(shape_owner, res.shape)
				var contacts:PackedVector2Array = query.shape.collide_and_get_contacts(query.transform, shape, 
					res.collider.global_transform * PhysicsServer2D.body_get_shape_transform(res.collider.get_rid(), res.shape))
				
				if(contacts.is_empty()):
					damage.position = res.collider.global_position
				else:
					damage.position = Array(contacts).reduce(func(a:Vector2,b:Vector2)->Vector2: return a+b)/contacts.size()
				
				damage.direction = (damage.position-global_position).normalized()
				damage.silent = damage_silent
				damage_dealt.emit(damage)
				damage.target.take_damage(damage)

func _process(_delta: float) -> void:
	if(!Engine.is_editor_hint()):
		queue_redraw()
		if(timer.time <= 0):
			queue_free()

func _draw()->void:
	if(!Engine.is_editor_hint()):
		material.set_shader_parameter('current_time', (duration-timer.time))
	draw_rect(Rect2(-radius,-radius,radius*2,radius*2),Color.WHITE)
