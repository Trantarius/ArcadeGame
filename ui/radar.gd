extends AspectRatioContainer

@export var color:Color
var lcurve:Curve

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lcurve = Curve.new()
	lcurve.add_point(Vector2(0,1))
	lcurve.add_point(Vector2(1,0))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for child:Node in $Control.get_children():
		child.queue_free()
	var enemies:Array = get_tree().get_nodes_in_group(&'Enemies')
	var campos:Vector2 = get_viewport().get_camera_2d().get_screen_center_position()
	for enemy:Enemy in enemies:
		if(enemy.radar_distance > 0 && (enemy.global_position - campos).length()<enemy.radar_distance):
			var arrow:Line2D = Line2D.new()
			arrow.add_point((enemy.global_position - campos).normalized() * 0.4 * $Control.size.x)
			arrow.add_point((enemy.global_position - campos).normalized() * 0.45 * $Control.size.x)
			arrow.width_curve = lcurve
			arrow.width = 64
			arrow.default_color = color
			$Control.add_child(arrow)
			arrow.position = $Control.size/2
