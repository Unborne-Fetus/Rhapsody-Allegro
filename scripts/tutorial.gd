extends RefCounted
## Objective gates advance only from real gameplay events, never a skip timer.
const LESSONS := [
	{"title":"FIND YOUR FEET","goal":"Walk into the glowing checkpoint on the right.","why":"Move with WASD, arrows, the left stick or the touch joystick.","event":"checkpoint","count":1},
	{"title":"CLOSE THE DISTANCE","goal":"Land three ordinary melee hits on the practice sentinel.","why":"Hold K, left mouse, controller X or STRIKE. Misses do not count.","event":"melee_hit","count":3},
	{"title":"YOUR CHARACTER'S ABILITY","goal":"Hit the sentinel with your character ability.","why":"Use J, right mouse, RT or ABILITY. Only Lyra fires bullets; the other characters must get close.","event":"ability_hit","count":1},
	{"title":"THROUGH THE DANGER","goal":"Dodge through one slow practice projectile.","why":"Space, controller A or DODGE grants brief protection. Crossing an actual shot earns a Perfect Dodge.","event":"perfect_dodge","count":1},
	{"title":"ENERGY AND RECOVERY","goal":"Land two melee hits to recover energy.","why":"Energy pays for abilities and dodging. Successful melee hits restore it. Move closer and strike.","event":"melee_hit","count":2},
	{"title":"RESONANCE BREAK","goal":"Use a full resonance meter to unleash a break.","why":"The meter is filled for this lesson. Press E, Y or BURST. In normal fights, attacks and perfect dodges earn it.","event":"burst","count":1},
	{"title":"A DIFFERENT FORM","goal":"Jump onto the first raised platform.","why":"W, Up, D-pad Up or JUMP. Holding down drops through a platform. Your attacks keep the same buttons.","event":"platform","count":1},
	{"title":"YOUR FIRST ENCOUNTER","goal":"Defeat the rehearsal sentinel using what you learned.","why":"Watch the gold warnings, dodge its sweep, use your ability and look for openings. This is a gentler tutorial opponent.","event":"victory","count":1}
]
var step := 0
var progress := 0
var transition := 0.0
var complete := false
func event(name: String) -> void:
	if complete or transition>0 or name != LESSONS[step].event: return
	progress += 1
	if progress>=int(LESSONS[step].count): transition = 0.7
func tick(delta: float) -> bool:
	if transition<=0 or complete: return false
	transition = maxf(0,transition-delta)
	if transition>0: return false
	step += 1; progress = 0
	if step>=LESSONS.size(): complete = true
	return true
