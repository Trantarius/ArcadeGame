class_name AreaAttack
extends Area2D

## How long a target is immune after taking damage.
@export var repeat_delay:float = 0.5

@export var damage_amount:float = 1
@export var damage_silent:bool = false

## Makes this node delete itself after [member lifetime] seconds.
@export var one_shot:bool = false
@export var lifetime:float = 1

func _physics_process(_delta: float) -> void:
	var bodies:Array = get_overlapping_bodies()
	for body:Object in bodies:
		if(body is Actor && !body.has_node(get_tag_name())):
	
			var immunity:Timer = Timer.new()
			immunity.name = get_tag_name()
			immunity.timeout.connect(immunity.queue_free)
			immunity.one_shot = true
			body.add_child(immunity)
			immunity.start(repeat_delay)
			
			var damage:Damage = Damage.new()
			damage.amount = damage_amount
			damage.source = self
			damage.attacker = source
			damage.target = body
			damage.position = body.position
			damage.direction = (position - body.position).normalized()
			damage.silent = damage_silent
			damage_dealt.emit(damage)
			damage.target.take_damage(damage)


func get_tag_name()->StringName:
	return "immunity_tag_"+str(get_instance_id())

var source:Actor

signal damage_dealt(damage:Damage)
