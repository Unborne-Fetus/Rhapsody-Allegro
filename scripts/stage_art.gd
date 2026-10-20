extends RefCounted
## A shared, lightweight pixel atlas for all twelve bosses.
## 768x528 pixels: twelve 64x88 columns, six pose rows each.
## Each boss has idle A/B, movement L/R, attack windup and hit-reaction.
const ATLAS: Texture2D = preload("res://assets/bosses-pixel.png")
const PixelPerformers = preload("res://scripts/pixel_performers.gd")
const CELL := Vector2(64,88)
const BOSS_HEIGHTS := [186.0,180.0,185.0,172.0,180.0,174.0,180.0,175.0,173.0,174.0,176.0,180.0]

static func region(index: int) -> Rect2:
	return Rect2(float(clampi(index,0,11))*CELL.x,0,CELL.x,CELL.y)

static func frame_for(g: Node2D,index: int) -> int:
	if g.screen != "playing" or g.shift_left>0.0:
		return int(g.total_time*2.5+index)%2
	if g.boss_flash>0.0:
		return 5
	if g.charge_time>0.0 or g.attack_timer<0.18:
		return 4
	# Two real movement poses alternate as the boss pursues the player.
	# All boss portraits also animate while the gallery is open.
	return 2 + int(g.total_time*7.0+index)%2

static func draw(g: Node2D,p: Vector2,index: int,height: float,flip: bool = false,alpha: float = 1.0,lean: float = 0.0) -> void:
	var source := region(index)
	source.position.y = float(frame_for(g,index))*CELL.y
	var width := height*CELL.x/CELL.y
	var rect := Rect2(p+Vector2(-width*0.5+lean,-height+28.0),Vector2(width,height))
	if flip:
		rect.position.x += width
		rect.size.x = -width
	g.draw_texture_rect_region(ATLAS,rect,source,Color(1,1,1,alpha),false,true)

static func boss(g: Node2D,p: Vector2,index: int,size: float) -> void:
	var flip: bool = g.screen=="playing" and g.boss.x>g.player.x
	draw(g,p,index,BOSS_HEIGHTS[clampi(index,0,11)]*size,flip)

static func player(g: Node2D,p: Vector2,index: int,alpha: float) -> void:
	PixelPerformers.player(g,p,index,alpha)

static func portrait(g: Node2D,p: Vector2,index: int) -> void:
	PixelPerformers.portrait(g,p,index)
