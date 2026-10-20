extends RefCounted
## Four finished musician designs, taken from the new transparent band artwork.
## PNG atlas: 320 x 320, 4 character columns by 4 action-pose rows.
## Each cell is 80x80; rows are idle, performance, left-foot step, right-foot step.
## The gameplay state machine continues to distinguish walking/jumping/hurt/attack,
## while every visible frame now uses the redesigned character silhouettes.
const ATLAS: Texture2D = preload("res://assets/musician-band.png")
const CELL := Vector2(80,80)
const SIZE := Vector2(104,104)

static func frame_for(g: Node2D, portrait: bool = false) -> int:
	if portrait:
		return 16 + int(g.total_time*3.0)%4
	if g.hurt_animation > 0.0:
		return 34 + int(g.elapsed*12.0)%2
	if g.attack_animation > 0.0:
		var completed: float = 1.0-float(g.attack_animation)/maxf(float(g.attack_visual_duration),0.01)
		return 30 + clampi(int(completed*4.0),0,3)
	if g.side:
		if g.ground_grace <= 0.0 and absf(g.velocity.y)>35.0:
			return 26 if g.velocity.y < -320.0 else (27 if g.velocity.y < 0.0 else (28 if g.velocity.y < 320.0 else 29))
		if absf(g.velocity.x)>35.0 or g.dash_time>0:
			return 20 + int(g.elapsed*13.0)%6
		return 16 + int(g.total_time*3.0)%4
	var direction: Vector2 = g.velocity if g.velocity.length()>35.0 else g.facing
	var base := 0
	if absf(direction.x)>absf(direction.y):
		base = 12 if direction.x>0.0 else 8
	else:
		base = 0 if direction.y>=0.0 else 4
	if g.velocity.length()<=35.0:
		return base + 1
	return base + int(g.elapsed*9.0)%4

static func pose_for(frame: int, moving: bool = true) -> int:
	if frame>=34: return 1
	if frame>=30:
		return [1,2,3,0][clampi(frame-30,0,3)]
	if frame>=26:
		return [1,2,3,0][clampi(frame-26,0,3)]
	if frame>=20:
		return 2 + posmod(frame-20,2)
	if frame>=16:
		return posmod(frame-16,2)
	if not moving: return 0
	return 2 + posmod(frame,2)

static func draw(g: Node2D,p: Vector2,character: int,frame: int,alpha: float = 1.0,flip: bool = false,scale: float = 1.0) -> void:
	var moving: bool = g.velocity.length()>35.0
	var pose := pose_for(frame,moving)
	var source := Rect2(float(clampi(character,0,3))*CELL.x,float(pose)*CELL.y,CELL.x,CELL.y)
	# Boots align to the same collision/shadow origin across all frames.
	# Size the atlas without filtering it. Small preview sprites should sit
	# fully inside cards rather than overlapping their title text.
	var preview_size := SIZE*scale
	var dest := Rect2(p+Vector2(-preview_size.x*0.5,-82.0*scale),preview_size)
	if flip:
		dest.position.x += preview_size.x
		dest.size.x = -preview_size.x
	g.draw_texture_rect_region(ATLAS,dest,source,Color(1,1,1,alpha),false,true)

static func player(g: Node2D,p: Vector2,character: int,alpha: float = 1.0) -> void:
	draw(g,p,character,frame_for(g),alpha,g.facing.x<0.0)

static func portrait(g: Node2D,p: Vector2,character: int,scale: float = 1.0) -> void:
	draw(g,p,character,frame_for(g,true),1.0,false,scale)
