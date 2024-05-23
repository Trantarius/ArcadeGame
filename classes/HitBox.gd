class_name HitBox
extends Area2D

## The actor this hitbox is for. If not set, the nearest parent that is an actor will be chosen.
@export var actor:Actor
## Multiplies damage passing through this.
@export var damage_multiplier:float = 1

## Enables dealing damage on contact.
@export var contact_damage_enabled:bool = false:
	set(to):
		contact_damage_enabled=to
		monitoring=to
## Amount of damage to deal on contact.
@export var contact_damage_amount:float = 5
## Time after taking contact damage that another actor is immune to contact damage from this hitbox.
@export var contact_damage_immunity_time:float = 0.25

signal damage_taken(damage:Damage)
signal damage_dealt(damage:Damage)

func _ready()->void:
	if(!is_instance_valid(actor)):
		var current:Node = get_parent()
		while(!(current is Actor)):
			if(current==get_tree().root || !is_instance_valid(current)):
				break
			current = current.get_parent()
		if(current is Actor):
			actor=current

func _init() -> void:
	area_shape_entered.connect(_area_shape_entered)

func take_damage(damage:Damage):
	damage.amount *= damage_multiplier
	damage_taken.emit(damage)
	actor.take_damage(damage)


func get_immunity_tag_name()->String:
	return 'contact_immunity_'+str(get_instance_id())

func _area_shape_entered(area_rid:RID, area:Area2D, area_shape_index:int, local_shape_index:int)->void:
	if(contact_damage_enabled && area is HitBox && !area.has_node(get_immunity_tag_name())):
			
		var contact:Dictionary = Util.collider_get_shape_contact(self, local_shape_index,
			area, area_shape_index)
		
		var damage:Damage = Damage.new()
		damage.amount = contact_damage_amount
		if(contact.is_empty()):
			damage.position = area.global_position
			damage.direction = (area.global_position - global_position).normalized()
		else:
			damage.position = contact.position
			damage.direction = contact.normal
		damage.attacker = actor
		damage.target = area.actor
		damage_dealt.emit(damage)
		area.take_damage(damage)
		
		var immune_tag:Timer = Timer.new()
		immune_tag.timeout.connect(immune_tag.queue_free)
		immune_tag.name = get_immunity_tag_name()
		area.add_child(immune_tag)
		immune_tag.start(contact_damage_immunity_time)
