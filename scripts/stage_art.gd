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
	# Do not animate an idle or staggered boss as though it were running.
	var idle := int(g.total_time*2.5+index)%2
	if g.screen != "playing" or g.shift_left>0.0:
		return idle
	if g.boss_flash>0.0 or g.stagger_time>0.0:
		return 5
	# The pose follows the actual warning and strike, not attack_timer, which
	# resets before each windup and used to skip most visible attacks.
	if g.windup>0.0 or g.charge_time>0.0 or g.boss_attack_recoil>0.0:
		return 4
	if g.songs.recovery>0.0 or (g.training and not g.training_attacks) or (g.tutorial_active and g.tutorial.step<7):
		return idle
	return 2 + int(g.total_time*7.0+index)%2

static func draw(g: Node2D,p: Vector2,index: int,height: float,flip: bool = false,alpha: float = 1.0,lean: float = 0.0) -> void:
	var source := region(index)
	source.position.y = float(frame_for(g,index))*CELL.y
	var width := height*CELL.x/CELL.y
	var rect := Rect2(p+Vector2(-width*0.5+lean,-height+28.0),Vector2(width,height))
	if flip:
		rect.position.x += width
		rect.size.x = -width
	# A gentle impact tint enhances the existing pixel art without replacing
	# its native palette or smoothing the nearest-neighbor sprite edges.
	var tint := Color(1.0,0.78,0.72,alpha) if g.screen == "playing" and g.boss_flash>0.0 else Color(1.0,1.0,1.0,alpha)
	g.draw_texture_rect_region(ATLAS,rect,source,tint,false,true)

static func boss(g: Node2D,p: Vector2,index: int,size: float) -> void:
	var flip: bool = g.screen=="playing" and g.boss.x>g.player.x
	draw(g,p,index,BOSS_HEIGHTS[clampi(index,0,11)]*size,flip)

static func player(g: Node2D,p: Vector2,index: int,alpha: float) -> void:
	PixelPerformers.player(g,p,index,alpha)

static func portrait(g: Node2D,p: Vector2,index: int,scale: float = 1.0) -> void:
	PixelPerformers.portrait(g,p,index,scale)
