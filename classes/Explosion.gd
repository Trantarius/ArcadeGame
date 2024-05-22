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
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.collision_mask = collision_mask
		query.shape = CircleShape2D.new()
		query.shape.radius = radius
		query.transform = global_transform
		var results:Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query,256)
		
		for res:Dictionary in results:
			if(res.collider is HitBox):
				var damage:Damage = Damage.new()
				damage.amount = damage_amount
				damage.source = self
				damage.attacker = source
				damage.target = res.collider.actor
				damage.position = global_position + (res.collider.global_position-global_position).limit_length(radius)
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
