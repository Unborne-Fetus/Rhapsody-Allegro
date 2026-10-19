extends RefCounted
## All area attacks warn before they become harmful. State has a bounded lifetime.
var kind: String
var origin: Vector2
var target: Vector2
var warning: float
var duration: float
var age := 0.0
var radius := 0.0
var previous_radius := 0.0
var width := 16.0
var speed := 240.0
var parryable := false
var hit := false
func _init(type: String,p: Vector2,to: Vector2,warn: float = 0.9,active: float = 1.1) -> void:
	kind = type; origin = p; target = to; warning = warn; duration = active
func step(delta: float) -> void:
	age += delta
	previous_radius = radius
	if active() and kind == "wave": radius += speed*delta
func active() -> bool:
	return age>=warning and age<warning+duration
func expired() -> bool:
	return hit or age>=warning+duration
func intersects(p: Vector2,body_radius: float = 14) -> bool:
	if not active() or hit: return false
	match kind:
		"beam": return Geometry2D.get_closest_point_to_segment(p,origin,target).distance_to(p)<width+body_radius
		"mine": return origin.distance_to(p)<55+body_radius
		"wave":
			var distance = p.distance_to(origin)
			return distance>=previous_radius-width-body_radius and distance<=radius+width+body_radius
	return false
