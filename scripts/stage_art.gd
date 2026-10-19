extends RefCounted
## One painted atlas, shared by combat and the character/practice galleries.
const ATLAS = preload("res://assets/performers-atlas.png")
const PixelPerformers = preload("res://scripts/pixel_performers.gd")
const BOSS_HEIGHTS := [186.0,180.0,185.0,172.0,180.0,174.0,180.0,175.0,173.0,174.0,176.0,180.0]
# Hand-fit source rectangles preserve full shoes, headpieces and instrument tips.
const REGIONS := [
	Rect2(0,0,337,335),Rect2(333,0,318,335),Rect2(648,0,308,335),Rect2(960,0,294,335),
	Rect2(0,337,335,302),Rect2(340,337,290,300),Rect2(648,337,292,300),Rect2(930,337,324,300),
	Rect2(0,639,325,297),Rect2(326,639,316,297),Rect2(650,639,290,297),Rect2(960,639,294,297),
	Rect2(0,932,326,322),Rect2(328,936,322,318),Rect2(647,936,300,318),Rect2(947,936,307,318)
]
static func region(index: int) -> Rect2:
	return REGIONS[clampi(index,0,15)]
static func draw(g: Node2D,p: Vector2,index: int,height: float,flip: bool = false,alpha: float = 1.0,lean: float = 0.0) -> void:
	var source = region(index)
	var width = height*source.size.x/source.size.y
	# Negative width flips around the same center; p is the combat body center.
	var rect = Rect2(p+Vector2(-width/2+lean,-height+28),Vector2(width,height))
	if flip: rect.size.x = -width
	g.draw_texture_rect_region(ATLAS,rect,source,Color(1,1,1,alpha),false,true)
static func boss(g: Node2D,p: Vector2,index: int,size: float) -> void:
	var moving: bool = g.screen == "playing" and g.shift_left<=0
	var bob = sin(g.total_time*2.6+index)*1.6 if moving else 0.0
	var lean = sin(g.total_time*2+index)*1.5 if moving else 0.0
	draw(g,p+Vector2(0,bob),index,BOSS_HEIGHTS[index]*size,false,1.0,lean*size)
static func player(g: Node2D,p: Vector2,index: int,alpha: float) -> void:
	# Enemy artwork stays painted for now; playable classes use real 36-pose sprites.
	PixelPerformers.player(g,p,index,alpha)

static func portrait(g: Node2D,p: Vector2,index: int) -> void:
	PixelPerformers.portrait(g,p,index)
