@tool
class_name Laser
extends Node2D

## How long the laser stays on screen (the attack itself is instant)
@export var lifetime:float = 0.25
var lifetime_timer:CountdownTimer = CountdownTimer.new()

@export var damage_amount:float = 1
@export var damage_silent:bool = false

@export_flags_2d_physics var collision_mask:int
@export var gradient:Gradient:
	set(to):
		gradient=to
		if(is_instance_valid(line)):
			var gtex:GradientTexture1D = line.material.get_shader_parameter('gradient')
			gtex.gradient = gradient
@export var length:float:
	set(to):
		length=to
		if(Engine.is_editor_hint() && is_instance_valid(line)):
			line.points = [Vector2.ZERO,Vector2.RIGHT*length]
@export var width:float:
	set(to):
		width = to
		if(is_instance_valid(line)):
			line.width=width

var line:Line2D
var source:Actor

signal damage_dealt(damage:Damage)

func _ready()->void:
	line = Line2D.new()
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.begin_cap_mode = Line2D.LINE_CAP_BOX
	line.end_cap_mode = Line2D.LINE_CAP_BOX
	line.material = ShaderMaterial.new()
	line.material.shader = preload("res://visual_effects/laser.gdshader")
	var gradtex:GradientTexture1D = GradientTexture1D.new()
	gradtex.gradient = gradient
	line.material.set_shader_parameter('gradient',gradtex)
	line.width = width
	lifetime_timer.min_time = 0
	add_child(line,false,Node.INTERNAL_MODE_BACK)
	if(Engine.is_editor_hint()):
		line.points = [Vector2.ZERO,Vector2.RIGHT*length]

func fire()->void:
	lifetime_timer.time = lifetime
	line.material.set_shader_parameter('shade_offset',0)
	var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.collision_mask = collision_mask
	query.from = global_position
	query.to = global_position + Vector2.RIGHT.rotated(global_rotation) * length
	var result:Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	
	if(result.is_empty()):
		line.points = [Vector2.ZERO,Vector2.RIGHT*length]
	else:
		line.points = [Vector2.ZERO,(result.position-global_position).length() * Vector2.RIGHT]
		var collider:Object = result.collider
		if(collider is Actor && !collider.invincible):
			var damage:Damage = Damage.new()
			damage.amount = damage_amount
			damage.source = self
			damage.attacker = source
			damage.target = collider
			damage.position = result.position
			damage.direction = (query.to-query.from).normalized()
			damage.silent = damage_silent
			damage_dealt.emit(damage)
			damage.target.take_damage(damage)
	
func _process(_delta: float) -> void:
	if(!Engine.is_editor_hint()):
		line.material.set_shader_parameter('shade_offset',(lifetime - lifetime_timer.time)/lifetime)
		if(lifetime_timer.time<=0):
			queue_free()
