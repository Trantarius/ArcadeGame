class_name Damage

## Amount of health to remove from the target.
var amount:float

## Actor responsible for causing the damage.
var attacker:Actor
## Actor that will take this damage.
var target:Actor

## Position of the contact point at which damage occurs.
var position:Vector2
## Direction of damage, as would be appropriate for applying knockback.
var direction:Vector2

## Disables hit numbers and on-damage effects.
var silent:bool = false
