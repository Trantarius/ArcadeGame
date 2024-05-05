class_name Damage

## Amount of health to remove from the target.
var amount:float

## Actor responsible for causing the damage.
var attacker:Actor
## Method of damage (a projectile or an actor).
var source:Node2D
## Actor that will take this damage.
var target:Actor

## Position of the contact point at which damage occurs.
var position:Vector2
## Velocity of the contact point.
var velocity:Vector2
## Direction of damage, as would be appropriate for applying knockback.
var direction:Vector2

## Disables hit numbers and on-damage effects.
var silent:bool = false
