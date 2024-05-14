class_name WeaponAbility
extends PlayerAbility

## Number of times [signal fire] is emitted per second.
@export var fire_rate:float = 3

## Damage per projectile (interpretation is up to subclass).
@export var damage_amount:float = 1

## Projectiles per shot (interpretation is up to subclass).
@export var projectile_count:float = 1

## Initial speed of projectiles (interpretation is up to subclass).
@export var projectile_speed:float = 600

## Radius of projectiles (interpretation is up to subclass).
@export var projectile_size:float = 16

var fire_timer:CountdownTimer = CountdownTimer.new()

signal fire

func _init()->void:
	activated.connect(_weapon_ability_activate)

func _weapon_ability_activate()->void:
	fire_timer.time = 1.0/fire_rate

func _process(_delta: float) -> void:
	if(fire_timer.time<0 && is_active):
		fire.emit()
		fire_timer.time += 1.0/fire_rate
