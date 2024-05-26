@tool
class_name Laser
extends Node2D

## How long the laser stays on screen (the attack itself is instant)
@export var lifetime:float = 0.25
var lifetime_timer:CountdownTimer = CountdownTimer.new()

@export var damage_amount:float = 1

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
	if(Engine.is_editor_hint()):
		fire()

func fire()->void:
	
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
	if(!Engine.is_editor_hint() && is_instance_valid(get_viewport().get_camera_2d())):
		get_viewport().get_camera_2d().add_child(line)
		line.global_transform = global_transform
	else:
		add_child(line,false,Node.INTERNAL_MODE_BACK)
	if(Engine.is_editor_hint()):
		line.points = [Vector2.ZERO,Vector2.RIGHT*length]
	
	if(!Engine.is_editor_hint()):
		lifetime_timer.time = lifetime
		line.material.set_shader_parameter('shade_offset',0)
		
		var results:Array[Dictionary] = Util.raycast(global_position, global_position + Vector2.from_angle(global_rotation) * length, collision_mask)
		for hit:Dictionary in results:
			if(hit.collider is HitBox):
				var damage:Damage = Damage.new()
				damage.amount = damage_amount
				damage.attacker = source
				damage.target = hit.collider.actor
				damage.position = hit.position
				damage.direction = Vector2.from_angle(global_rotation)
				damage_dealt.emit(damage)
				damage.target.take_damage(damage)
		
		if(results.is_empty()):
			line.points = [Vector2.ZERO,Vector2.RIGHT*length]
		else:
			line.points = [Vector2.ZERO, global_transform.affine_inverse() * results.back().position]
	
func _process(_delta: float) -> void:
	if(!Engine.is_editor_hint()):
		line.material.set_shader_parameter('shade_offset',(lifetime - lifetime_timer.time)/lifetime)
		if(lifetime_timer.time<=0):
			if(is_instance_valid(line)):
				line.queue_free()
			queue_free()
