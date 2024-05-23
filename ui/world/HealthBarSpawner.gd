extends Node

## Enables a health bar beneath the player
@export var enable_on_player:bool = true:
	set(to):
		if(enable_on_player != to):
			enable_on_player = to
			if(is_inside_tree()):
				refresh_player()
func refresh_player()->void:
	for healthbar:Node in get_tree().get_nodes_in_group(&'HealthBars'):
		if(healthbar.get_parent() is Player):
			healthbar.queue_free()
	if(enable_on_player):
		for player:Player in get_tree().get_nodes_in_group(&'Players'):
			give_healthbar(player)
		


## Enables a health bar beneath each enemy
@export var enable_on_enemy:bool = true:
	set(to):
		if(enable_on_enemy != to):
			enable_on_enemy = to
			if(is_inside_tree()):
				refresh_enemy()
func refresh_enemy()->void:
	for healthbar:Node in get_tree().get_nodes_in_group(&'HealthBars'):
		if(healthbar.get_parent() is Enemy):
			healthbar.queue_free()
	if(enable_on_enemy):
		for enemy:Enemy in get_tree().get_nodes_in_group(&'Enemies'):
			give_healthbar(enemy)

## Causes healthbars to only show on enemies that have been damaged
@export var damaged_enemies_only:bool = true:
	set(to):
		if(damaged_enemies_only!=to):
			damaged_enemies_only=to
			if(is_inside_tree()):
				for healthbar:Node in get_tree().get_nodes_in_group(&'HealthBars'):
					if(healthbar.get_parent() is Enemy):
						healthbar.hide_when_full = damaged_enemies_only

func _ready() -> void:
	refresh_player()
	refresh_enemy()
	Actor.something_spawned.connect(_on_something_spawned)

func _on_something_spawned(actor:Actor)->void:
	if(actor.disable_health_bar):
		return
	if(actor is Player && enable_on_player):
		give_healthbar(actor)
	elif(actor is Enemy && enable_on_enemy):
		give_healthbar(actor)

func give_healthbar(actor:Actor)->void:
	var hbar:Node2D = preload("res://ui/world/health_bar.tscn").instantiate()
	if(actor is Enemy and damaged_enemies_only):
		hbar.hide_when_full=true
	actor.add_child(hbar)
