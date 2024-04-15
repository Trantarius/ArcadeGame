class_name Damage

var amount:float

## Actor responsible for causing the damage
var attacker:Actor
## Method of damage (a projectile or an actor)
var source:Node2D
## Actor that will take this damage
var target:Actor

var position:Vector2
var direction:Vector2
