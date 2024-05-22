extends Node

## Creates hit numbers when something damages the player
@export var enable_on_player:bool = false
@export var player_color:Color

## Creates hit numbers when something damages an enemy
@export var enable_on_enemy:bool = false
@export var enemy_color:Color

## Forces hit numbers to spawn on silent damage events
@export var enable_silent:bool = false

func _ready() -> void:
	Actor.something_took_damage.connect(_on_something_took_damage)

func _on_something_took_damage(damage:Damage)->void:
	if(damage.silent && !enable_silent):
		return
		
	var show_number:bool = false
	var color:Color
	if(damage.target is Player && enable_on_player):
		show_number = true
		color = player_color
	elif(damage.target is Enemy && enable_on_enemy):
		show_number = true
		color = enemy_color
	
	if(show_number):
		var num:HitNumber = HitNumber.new()
		num.position = damage.position
		num.number = roundi(damage.amount)
		num.velocity = damage.target.get_average_velocity() + damage.direction * 64
		num.velocity += Vector2(randfn(0,32),randfn(0,32))
		num.modulate = color
		add_child(num)
		
