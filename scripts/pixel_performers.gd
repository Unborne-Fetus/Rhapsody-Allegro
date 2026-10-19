extends RefCounted
## Four original musician silhouettes. Each performer has 36 distinct hand-keyed pixel poses.
## The SVG is a *pixel sprite atlas*, not a painted still with positional bobbing.
## Cell size: 40x56. Row = class. Columns:
## 0..3 down, 4..7 up, 8..11 left, 12..15 right,
## 16..19 side idle, 20..25 side run, 26..29 jump,
## 30..33 attack, 34..35 hurt.
const ATLAS: Texture2D = preload("res://assets/musicians.svg")
const CELL := Vector2(40,56)
const SIZE := Vector2(80,112)

static func frame_for(g: Node2D, portrait: bool = false) -> int:
	if portrait:
		return 16 + int(g.total_time*3.0)%4
	if g.hurt_animation > 0.0:
		return 34 + int(g.elapsed*12.0)%2
	if g.attack_animation > 0.0:
		return 30 + clampi(int((0.36-g.attack_animation)*12.0),0,3)
	if g.side:
		if g.ground_grace <= 0.0 and absf(g.velocity.y)>35.0:
			return 26 if g.velocity.y < -320.0 else (27 if g.velocity.y < 0.0 else (28 if g.velocity.y < 320.0 else 29))
		if absf(g.velocity.x)>35.0 or g.dash_time>0:
			return 20 + int(g.elapsed*13.0)%6
		return 16 + int(g.total_time*3.0)%4
	# Walk direction follows motion rather than aim, allowing phone retreat animations.
	var direction: Vector2 = g.velocity if g.velocity.length()>35.0 else g.facing
	var base := 0
	if absf(direction.x)>absf(direction.y):
		base = 12 if direction.x>0.0 else 8
	else:
		base = 0 if direction.y>=0.0 else 4
	if g.velocity.length()<=35.0:
		return base + 1
	return base + int(g.elapsed*9.0)%4

static func draw(g: Node2D,p: Vector2,character: int,frame: int,alpha: float = 1.0,flip: bool = false) -> void:
	var source := Rect2(float(clampi(frame,0,35))*CELL.x,float(clampi(character,0,3))*CELL.y,CELL.x,CELL.y)
	# Ankles meet the existing combat shadow; foot placement is steady across frames.
	var dest := Rect2(p+Vector2(-SIZE.x*0.5,-86),SIZE)
	if flip:
		dest.position.x += SIZE.x
		dest.size.x = -SIZE.x
	g.draw_texture_rect_region(ATLAS,dest,source,Color(1,1,1,alpha),false,true)

static func player(g: Node2D,p: Vector2,character: int,alpha: float = 1.0) -> void:
	draw(g,p,character,frame_for(g),alpha,g.side and g.facing.x<0.0)

static func portrait(g: Node2D,p: Vector2,character: int) -> void:
	draw(g,p,character,frame_for(g,true))
