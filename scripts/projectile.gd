extends RefCounted
## Simulation data, separate from rendering; bounded lifetime prevents accumulation.
var position: Vector2
var previous: Vector2
var velocity: Vector2
var friendly: bool
var radius: float
var life := 6.0
var damage: float
func _init(p: Vector2, v: Vector2, ally: bool, power: float = 9.0, size: float = 6.0) -> void:
	position = p
	previous = p
	velocity = v
	friendly = ally
	damage = power
	radius = size
func step(delta: float) -> void:
	previous = position
	position += velocity*delta
	life -= delta
func intersects(center: Vector2, body_radius: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(center,previous,position).distance_to(center) < radius+body_radius
