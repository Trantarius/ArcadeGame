extends PlayerAbility

var fire_rate:Stat = Stat.new(1, 0, INF)
var damage:Stat = Stat.new(5, 0, INF)
var projectile_count:Stat = Stat.new(8, 1, INF, Stat.PERIODIC)
var projectile_speed:Stat = Stat.new(600, 0, INF)
var projectile_size:Stat = Stat.new(8, 1, INF)

const proj_spread:float = PI/6
signal fired

func _ready()->void:
	$FireTimer.duration = 1.0/fire_rate.get_value()
	$FireTimer.reset()
	$FireTimer.start()


func _on_fire_timer_timeout_precise(ago: float) -> void:
	var proj_count:int = projectile_count.get_value()
	
	var mpos:Vector2 = get_parent().get_muzzle_position()
	var mdir:Vector2 = get_parent().get_muzzle_direction()
	
	var t0:float = -proj_spread if proj_count>1 else 0
	var dt:float = proj_spread*2/(proj_count-1) if proj_count>1 else 0
	
	for n:int in range(proj_count):
		var bullet:Projectile = preload("res://abilities/weapon/light_cannon/light_cannon_projectile.tscn").instantiate()
		bullet.global_position = mpos
		
		bullet.linear_velocity = projectile_speed.get_value() * mdir.rotated(t0+dt*n) + get_parent().linear_velocity
		bullet.source = get_parent()
		bullet.damage_amount = damage.get_value()
		bullet.scale = Vector2.ONE * projectile_size.get_value()/8
		get_tree().current_scene.add_child(bullet)
	
	fired.emit()
	$FireTimer.duration = 1.0/fire_rate.get_value()
