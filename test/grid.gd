@tool
class_name Grid
extends Node2D

@export var color:Color:
	set(to):
		color = to
		queue_redraw()
@export var thickness:float:
	set(to):
		thickness = to
		queue_redraw()
@export var separation:float:
	set(to):
		separation = to
		queue_redraw()

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var rect:Rect2 = get_canvas_transform().affine_inverse() * get_viewport_rect()
	
	var left:float = floor((rect.position.x-thickness)/separation)*separation
	var right:float = ceil((rect.end.x+thickness)/separation)*separation
	var top:float = floor((rect.position.y-thickness)/separation)*separation
	var bottom:float = ceil((rect.end.y+thickness)/separation)*separation
	
	if(is_nan(left)||is_inf(left)||is_nan(right)||is_inf(right)||is_nan(top)||is_inf(top)||is_nan(bottom)||is_inf(bottom)):
		return
	if((right-left)/separation>100 || (bottom-top)/separation>100):
		return
	
	var x:float = left
	while(x<=right):
		draw_line(Vector2(x,top),Vector2(x,bottom),color,thickness)
		x+=separation
	var y:float = top
	while(y<=bottom):
		draw_line(Vector2(left,y),Vector2(right,y),color,thickness)
		y+=separation
