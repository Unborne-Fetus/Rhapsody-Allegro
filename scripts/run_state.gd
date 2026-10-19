extends RefCounted
## Run progression and tuning, independent of scene/input/rendering.
const WEAPONS := [
	{"name":"NEEDLE","description":"Fast, accurate single shots","cost":3.0,"cooldown":0.14,"damage":9.0,"speed":850.0,"count":1,"spread":0.0},
	{"name":"CHORUS","description":"Close-range three-shot fan","cost":7.0,"cooldown":0.32,"damage":10.0,"speed":730.0,"count":3,"spread":0.13},
	{"name":"RAIL","description":"Slow, high-impact precision bolt","cost":12.0,"cooldown":0.66,"damage":46.0,"speed":1450.0,"count":1,"spread":0.0}
]
const DIFFICULTIES := [
	{"name":"ALLEGRO","description":"The intended first playthrough","damage":1.0,"speed":1.0,"interval":1.0,"density":0},
	{"name":"VIRTUOSO","description":"Faster patterns, narrower openings","damage":1.2,"speed":1.15,"interval":0.85,"density":2},
	{"name":"MAESTRO","description":"Dense patterns for repeat performances","damage":1.4,"speed":1.3,"interval":0.72,"density":4}
]
const UPGRADES := [
	{"id":"edge","name":"TEMPERED EDGE","line1":"Blade damage +20%","line2":"Dash strikes hit harder too.","icon":"blade"},
	{"id":"cell","name":"DEEP CAPACITOR","line1":"Maximum energy +25","line2":"Longer volleys before closing in.","icon":"cell"},
	{"id":"step","name":"QUICKSTEP","line1":"Dodge cost 18 · cooldown 0.36s","line2":"More movement, less downtime.","icon":"step"},
	{"id":"guard","name":"GOLDEN WINDOW","line1":"Parry window +0.08 seconds","line2":"Reflections build boss stagger.","icon":"guard"},
	{"id":"fire","name":"OVERTONE","line1":"Ranged damage +20%","line2":"Applies to all three weapons.","icon":"fire"},
	{"id":"heart","name":"SECOND WIND","line1":"Maximum vitality +25","line2":"Restore health before the next fight.","icon":"heart"},
	{"id":"siphon","name":"LIFELINE","line1":"Successful blade hits restore 2 HP","line2":"Sustain yourself at close range.","icon":"heart"},
	{"id":"echo","name":"RESONANT CORE","line1":"Resonance gain +35%","line2":"Reach the next break sooner.","icon":"echo"}
]
var upgrades: Array[String] = []
var seed_value := 0
var assisted := false
var difficulty := 0
var score := 0
var time := 0.0
var hits := 0
func reset(level: int = 0) -> void:
	upgrades.clear(); score = 0; time = 0; hits = 0; assisted = false
	difficulty = clampi(level,0,2)
	seed_value = randi_range(1,1000000000)
func has(id: String) -> bool:
	return id in upgrades
func stat(name: String) -> float:
	match name:
		"health": return 125.0 if has("heart") else 100.0
		"energy": return 125.0 if has("cell") else 100.0
		"melee": return 1.2 if has("edge") else 1.0
		"ranged": return 1.2 if has("fire") else 1.0
		"dodge_cost": return 18.0 if has("step") else 24.0
		"dodge_cd": return 0.36 if has("step") else 0.48
		"parry": return 0.28 if has("guard") else 0.2
		"resonance": return 1.35 if has("echo") else 1.0
	return 1.0
func choices(boss_index: int) -> Array:
	var available = UPGRADES.filter(func(u): return not has(u.id))
	var result: Array = []
	if available.is_empty(): return result
	var random = RandomNumberGenerator.new()
	random.seed = seed_value+boss_index*7919+difficulty*17
	for i in range(available.size()-1,0,-1):
		var other = random.randi_range(0,i)
		var temp = available[i]; available[i] = available[other]; available[other] = temp
	for i in mini(3,available.size()): result.append(available[i])
	return result
func snapshot(next_boss: int,assist: bool) -> Dictionary:
	return {"seed":seed_value,"boss":next_boss,"upgrades":upgrades.duplicate(),"difficulty":difficulty,"assist":assist or assisted,"score":score,"time":time,"hits":hits}
func restore(value: Dictionary) -> bool:
	if not value.get("boss") is float and not value.get("boss") is int: return false
	if int(value.boss)<0 or int(value.boss)>2: return false
	reset(int(number(value.get("difficulty",0))))
	seed_value = int(number(value.get("seed",1)))
	assisted = value.get("assist",false) == true
	if value.get("upgrades") is Array:
		for id in value.upgrades:
			if id is String and UPGRADES.any(func(u): return u.id == id) and not has(id): upgrades.append(id)
	score = maxi(0,int(number(value.get("score",0))))
	time = maxf(0,number(value.get("time",0)))
	hits = maxi(0,int(number(value.get("hits",0))))
	return true

static func number(value: Variant) -> float:
	if (value is int or value is float) and is_finite(float(value)): return float(value)
	return 0.0
