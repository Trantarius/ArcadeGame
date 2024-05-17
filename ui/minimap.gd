extends Control

@export var radar_range:float = 100.0

@export var asteroid_color:Color
@export var enemy_color:Color
@export var player_color:Color

var center:Vector2
@export var circle_tex:Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	queue_redraw()

func _draw()->void:
	center = get_viewport().get_camera_2d().get_screen_center_position()
	var tform:Transform2D = Transform2D.IDENTITY.translated(-center).scaled(size/radar_range).translated(size/2)
	draw_set_transform_matrix(tform)
	
	var asteroids:Array = get_tree().get_nodes_in_group(&'Asteroids')
	for asteroid:Asteroid in asteroids:
		if(asteroid.polygon_low.size()>=3):
			draw_set_transform_matrix(tform * asteroid.global_transform)
			draw_colored_polygon(asteroid.polygon_low,asteroid_color)
	
	draw_set_transform_matrix(tform)
	draw_group(&'Enemies',enemy_color)
	draw_group(&'Players',player_color)

func draw_group(group:StringName, color:Color)->void:
	var nodes:Array = get_tree().get_nodes_in_group(group)
	for node:Node2D in nodes:
		var radius = max(node.radius,radar_range/size.x/2) * 1.5;
		draw_texture_rect(circle_tex,Rect2(node.global_position-Vector2(radius,radius),
			Vector2(radius,radius)*2),false,color)
		#draw_circle(node.global_position, max(node.radius,radar_range/size.x/2), color)
