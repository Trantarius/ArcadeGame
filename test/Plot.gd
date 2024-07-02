@tool
class_name Plot
extends Control

enum {
	# entry format: {'type':SCATTER, 'color':Color, 'radius':float, 'points':PackedVector2Array}
	SCATTER,
	# entry format: {'type':LINE, 'color':Color, 'width':float, 'points':PackedVector2Array}
	LINE,
	# entry format: {'type':HLINE, 'color':Color, 'width':float, 'value':float}
	HLINE,
	# entry format: {'type':VLINE, 'color':Color, 'width':float, 'value':float}
	VLINE}

@export var data:Dictionary:
	set(to):
		data=to
		queue_redraw()

@export var background_color:Color:
	set(to):
		background_color=to
		queue_redraw()

@export var foreground_color:Color:
	set(to):
		foreground_color=to
		queue_redraw()

@export var legend:bool = false:
	set(to):
		legend=to
		queue_redraw()

@export_group('Margins')
@export var left_margin:float:
	set(to):
		left_margin=to
		queue_redraw()
@export var right_margin:float:
	set(to):
		right_margin=to
		queue_redraw()
@export var top_margin:float:
	set(to):
		top_margin=to
		queue_redraw()
@export var bottom_margin:float:
	set(to):
		bottom_margin=to
		queue_redraw()
@export var axis_margin:float:
	set(to):
		axis_margin=to
		queue_redraw()

@export_group('X Axis', 'x_')
@export var x_axis:bool = true:
	set(to):
		x_axis=to
		queue_redraw()
@export var x_auto_range:bool = true:
	set(to):
		x_auto_range=to
		queue_redraw()
@export var x_min:float:
	set(to):
		x_min=to
		queue_redraw()
@export var x_max:float:
	set(to):
		x_max=to
		queue_redraw()
@export var x_ticks:int = 5:
	set(to):
		x_ticks=to
		queue_redraw()
@export var x_tick_format:String='%.2f':
	set(to):
		x_tick_format=to
		queue_redraw()

@export_group('Y Axis', 'y_')
@export var y_axis:bool = true:
	set(to):
		y_axis=to
		queue_redraw()
@export var y_auto_range:bool = true:
	set(to):
		y_auto_range=to
		queue_redraw()
@export var y_min:float:
	set(to):
		y_min=to
		queue_redraw()
@export var y_max:float:
	set(to):
		y_max=to
		queue_redraw()
@export var y_ticks:int = 5:
	set(to):
		y_ticks=to
		queue_redraw()
@export var y_tick_format:String='%.2f':
	set(to):
		y_tick_format=to
		queue_redraw()



var data_range:Rect2:
	set(to):
		x_min=min(to.position.x,to.end.x)
		y_min=min(to.position.y,to.end.y)
		x_max=max(to.position.x,to.end.x)
		y_max=max(to.position.y,to.end.y)
	get:
		return Rect2(x_min, y_min, x_max-x_min, y_max-y_min)

const tick_length:float = 4

func local_to_data(local:Vector2)->Vector2:
	local -= Vector2(left_margin,top_margin)
	local.x /= (size.x-right_margin-left_margin)
	local.y /= (size.y-bottom_margin-top_margin)
	local.y = 1.0-local.y
	local *= data_range.size
	local += data_range.position
	return local

func data_to_local(point:Vector2)->Vector2:
	point -= data_range.position
	point /= data_range.size
	point.y = 1.0-point.y
	point.y *= (size.y-bottom_margin-top_margin)
	point.x *= (size.x-right_margin-left_margin)
	point += Vector2(left_margin,top_margin)
	return point

func add_plot(pname:StringName, plot:Dictionary)->void:
	data[pname]=plot
	queue_redraw()

func remove_plot(pname:StringName)->void:
	data.erase(pname)
	queue_redraw()

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),background_color)
	
	if(x_auto_range):
		__x_auto_range()
	if(y_auto_range):
		__y_auto_range()
	
	for pname:Variant in data:
		if(!((pname is String || pname is StringName) && data[pname] is Dictionary && data[pname].has(&'type'))):
			continue
		
		match data[pname].type:
			SCATTER:
				if(!(data[pname].has(&'points') && data[pname].points is PackedVector2Array)):
					continue
				for p:Vector2 in data[pname].points:
					__draw_scatter(data_to_local(p), data[pname])
			LINE:
				if(!(data[pname].has(&'points') && data[pname].points is PackedVector2Array)):
					continue
				for n:int in range(data[pname].points.size()-1):
					__draw_line(data_to_local(data[pname].points[n]),data_to_local(data[pname].points[n+1]), data[pname])
			
			HLINE:
				if(!(data[pname].has(&'value') && data[pname].value is float)):
					continue
				var yl:float = data_to_local(Vector2(0,data[pname].value)).y
				__draw_line(Vector2(left_margin, yl), Vector2(size.x-right_margin,yl),data[pname])
			
			VLINE:
				if(!(data[pname].has(&'value') && data[pname].value is float)):
					continue
				var xl:float = data_to_local(Vector2(data[pname].value,0)).x
				__draw_line(Vector2(xl,top_margin), Vector2(xl,size.y-bottom_margin),data[pname])
	
	if(x_axis):
		__draw_x_axis()
	if(y_axis):
		__draw_y_axis()
	if(legend):
		__draw_legend()


func __x_auto_range()->void:
	x_min=INF
	x_max=-INF
	
	for pname:Variant in data:
		if(!((pname is String || pname is StringName) && data[pname] is Dictionary && data[pname].has(&'type'))):
			continue
		
		match data[pname].type:
			SCATTER, LINE:
				if(!(data[pname].has(&'points') && data[pname].points is PackedVector2Array)):
					continue
				for p:Vector2 in data[pname].points:
					x_min = min(x_min, p.x)
					x_max = max(x_max, p.x)
			VLINE:
				if(!(data[pname].has(&'value') && data[pname].value is float)):
					continue
				x_min = min(x_min, data[pname].value)
				x_max = max(x_max, data[pname].value)
	if(!is_finite(x_min)):
		x_min = 0
	if(!is_finite(x_max)):
		x_max = 1

func __y_auto_range()->void:
	y_min=INF
	y_max=-INF
	
	for pname:Variant in data:
		if(!((pname is String || pname is StringName) && data[pname] is Dictionary && data[pname].has(&'type'))):
			continue
		
		match data[pname].type:
			SCATTER, LINE:
				if(!(data[pname].has(&'points') && data[pname].points is PackedVector2Array)):
					continue
				for p:Vector2 in data[pname].points:
					y_min = min(y_min, p.y)
					y_max = max(y_max, p.y)
			HLINE:
				if(!(data[pname].has(&'value') && data[pname].value is float)):
					continue
				y_min = min(y_min, data[pname].value)
				y_max = max(y_max, data[pname].value)
	if(!is_finite(y_min)):
		y_min=0
	if(!is_finite(y_max)):
		y_max=1
	
func __draw_x_axis()->void:
	draw_line(Vector2(left_margin-axis_margin,size.y-bottom_margin+axis_margin),
			  Vector2(size.x-right_margin+axis_margin,size.y-bottom_margin+axis_margin),foreground_color)
	if(x_ticks>1):
		var xt:float = 0
		while(xt<1.0+(1.0/(x_ticks-1)/2)):
			var data_x:float = lerp(data_range.position.x,data_range.end.x,xt)
			var local_x:float = lerp(left_margin,size.x-right_margin,xt)
			draw_line(Vector2(local_x,size.y-bottom_margin+axis_margin),Vector2(local_x,size.y-bottom_margin+tick_length+axis_margin),foreground_color)
			var fsize:float = get_theme_default_font_size()
			var font:Font = get_theme_default_font()
			var lbl:String = x_tick_format%[data_x]
			var lbl_size:Vector2  = font.get_string_size(lbl,0,-1,fsize)
			draw_string(font, Vector2(local_x-lbl_size.x/2, size.y-bottom_margin+tick_length+2+fsize+axis_margin), lbl, 
				0, -1, fsize, foreground_color)
			
			xt+=1.0/(x_ticks-1)

func __draw_y_axis()->void:
	draw_line(Vector2(left_margin-axis_margin,top_margin-axis_margin),Vector2(left_margin-axis_margin,size.y-bottom_margin+axis_margin),foreground_color)
	if(y_ticks>1):
		var yt:float = 0
		while(yt<1.0+(1.0/(y_ticks-1)/2)):
			var data_y:float = lerp(data_range.position.y,data_range.end.y,yt)
			var local_y:float = lerp(size.y-bottom_margin,top_margin,yt)
			draw_line(Vector2(left_margin-axis_margin,local_y),Vector2(left_margin-tick_length-axis_margin,local_y),foreground_color)
			var fsize:float = get_theme_default_font_size()
			var font:Font = get_theme_default_font()
			var lbl:String = y_tick_format%[data_y]
			var lbl_size:Vector2  = font.get_string_size(lbl,0,-1,fsize)
			draw_string(font, Vector2(left_margin-tick_length-2-lbl_size.x-axis_margin, local_y+fsize/2), lbl, 
				0, -1, fsize, foreground_color)
			
			yt+=1.0/(y_ticks-1)


func __draw_line(p1:Vector2,p2:Vector2,params:Dictionary)->void:
	var color:Color = params.color if params.has(&'color') && params.color is Color else foreground_color
	var width:float = params.width if params.has(&'width') && params.width is float && params.width>0 else -1
	draw_line(p1,p2,color,width)

func __draw_scatter(p:Vector2, params:Dictionary)->void:
	var color:Color = params.color if params.has(&'color') && params.color is Color else foreground_color
	var radius:float = params.radius if params.has(&'radius') && params.radius is float && params.radius>1 else 1
	draw_circle(p, radius, color)

func __draw_legend()->void:
	var fsize:float = get_theme_default_font_size()
	var font:Font = get_theme_default_font()
	var lpos:float = top_margin + fsize
	var isize:float = fsize*0.75
	for pname:Variant in data:
		if(!((pname is String || pname is StringName) && data[pname] is Dictionary && data[pname].has(&'type'))):
			continue
		if(pname.begins_with('_')):
			continue
		var iconrect:Rect2 = Rect2(size.x-right_margin+axis_margin,lpos-isize,isize,isize)
		
		match data[pname].type:
			SCATTER:
				if(!(data[pname].has(&'points') && data[pname].points is PackedVector2Array)):
					continue
				__draw_scatter(iconrect.position+iconrect.size/2, data[pname])
		
			LINE:
				if(!(data[pname].has(&'points') && data[pname].points is PackedVector2Array)):
					continue
				__draw_line(Vector2(iconrect.position.x,iconrect.end.y),Vector2(iconrect.end.x,iconrect.position.y), data[pname])
			
			HLINE:
				if(!(data[pname].has(&'value') && data[pname].value is float)):
					continue
				__draw_line(Vector2(iconrect.position.x,iconrect.position.y+iconrect.size.y/2), Vector2(iconrect.end.x,iconrect.position.y+iconrect.size.y/2), data[pname])
			
			VLINE:
				if(!(data[pname].has(&'value') && data[pname].value is float)):
					continue
				__draw_line(Vector2(iconrect.position.x+iconrect.size.x/2, iconrect.position.y), Vector2(iconrect.position.x+iconrect.size.x/2, iconrect.end.y), data[pname])
		
		draw_string(font, iconrect.end+Vector2(fsize/2,0), pname, 0, -1, fsize, foreground_color)
		lpos += fsize+2
