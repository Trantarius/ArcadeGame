extends PlayerAbility

@export var fire_rate:Stat
@export var damage:Stat
@export var projectile_count:Stat
@export var projectile_speed:Stat
@export var projectile_size:Stat

const proj_spread:float = PI/6
signal fired

func _ready()->void:
	$FireTimer.duration = 1.0/fire_rate.get_value()
	$FireTimer.reset()
	$FireTimer.start()


func _on_fire_timer_timeout_precise(ago: float) -> void:
	var proj_count:int = projectile_count.get_value()
	
	var lin_err:Vector2 = -get_parent().linear_velocity * ago
	var ang_err:float = -get_parent().angular_velocity * ago
	var mpos:Vector2 = (get_parent().get_muzzle_position() - get_parent().global_position
		).rotated(ang_err) + get_parent().global_position + lin_err
	var mdir:Vector2 = get_parent().get_muzzle_direction().rotated(ang_err)
	
	var t0:float = -proj_spread if proj_count>1 else 0
	var dt:float = proj_spread*2/(proj_count-1) if proj_count>1 else 0
	
	for n:int in range(proj_count):
		var bullet:Projectile = preload("res://abilities/weapon/light_cannon/light_cannon_projectile.tscn").instantiate()
		bullet.global_position = mpos
		
		bullet.linear_velocity = projectile_speed.get_value() * mdir.rotated(t0+dt*n) + get_parent().linear_velocity
		bullet.attacker = get_parent()
		bullet.source = self
		bullet.damage_amount = damage.get_value()
		bullet.scale = Vector2.ONE * projectile_size.get_value()/8
		bullet.global_position += bullet.linear_velocity * ago
		get_tree().current_scene.add_child(bullet)
	
	fired.emit()
	$FireTimer.duration = 1.0/fire_rate.get_value()
