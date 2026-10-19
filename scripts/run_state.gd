extends RefCounted
## Run progression and tuning, independent of scene/input/rendering.
const CombatRules = preload("res://scripts/combat_rules.gd")
const Encounters = preload("res://scripts/encounters.gd")
const Arsenal = preload("res://scripts/weapons.gd")
const Characters = preload("res://scripts/characters.gd")
const WEAPONS = Arsenal.SETS
const DIFFICULTIES := [
	{"name":"ALLEGRO","description":"The intended first playthrough","damage":1.0,"speed":1.0,"interval":1.0,"density":0},
	{"name":"VIRTUOSO","description":"Faster patterns, narrower openings","damage":1.2,"speed":1.15,"interval":0.85,"density":2},
	{"name":"MAESTRO","description":"Dense patterns for repeat performances","damage":1.4,"speed":1.3,"interval":0.72,"density":4}
]
const UPGRADES := [
	{"id":"edge","name":"TEMPERED EDGE","line1":"Blade damage +20%","line2":"Dash strikes hit harder too.","icon":"blade"},
	{"id":"cell","name":"DEEP CAPACITOR","line1":"Maximum energy +25","line2":"A larger reserve for skills and dodges.","icon":"cell"},
	{"id":"step","name":"QUICKSTEP","line1":"Dodge cost and recovery -25%","line2":"More movement, less downtime.","icon":"step"},
	{"id":"guard","name":"GOLDEN WINDOW","line1":"Parry window +0.08 seconds","line2":"Parries build resonance and stagger.","icon":"guard"},
	{"id":"fire","name":"OVERTONE","line1":"Character ability damage +20%","line2":"Boosts your character-specific skill.","icon":"fire"},
	{"id":"heart","name":"SECOND WIND","line1":"Maximum vitality +25","line2":"Restore health before the next fight.","icon":"heart"},
	{"id":"siphon","name":"LIFELINE","line1":"Blade hits heal 5% of base damage","line2":"Sustain yourself at close range.","icon":"heart"},
	{"id":"echo","name":"RESONANT CORE","line1":"Resonance gain +35%","line2":"Reach the next break sooner.","icon":"echo"},
	{"id":"flow","name":"STEADY RHYTHM","line1":"Energy regeneration +25%","line2":"Recover your reserve faster.","icon":"cell"},
	{"id":"armor","name":"STAGE ARMOR","line1":"Incoming damage -15%","line2":"Every hit takes a smaller toll.","icon":"heart"},
	{"id":"impact","name":"HEAVY ACCENT","line1":"Stagger gain +25%","line2":"Create more openings for damage.","icon":"blade"},
	{"id":"power","name":"ENCORE POWER","line1":"All direct damage +10%","line2":"Strengthens strikes and abilities.","icon":"fire"},
	{"id":"reserve","name":"DEEPER RESERVES","line1":"Maximum energy +20 more","line2":"Stacks with Deep Capacitor.","icon":"cell"}
]
var upgrades: Array[String] = []
var loadout_index := Arsenal.DEFAULT
var seed_value := 0
var assisted := false
var difficulty := 0
var score := 0
var time := 0.0
var hits := 0
func reset(level: int = 0) -> void:
	upgrades.clear(); score = 0; time = 0; hits = 0; assisted = false; loadout_index = Arsenal.DEFAULT
	difficulty = clampi(level,0,2)
	seed_value = randi_range(1,1000000000)
func has(id: String) -> bool:
	return id in upgrades
func stat(name: String) -> float:
	match name:
		"health": return float(Characters.ROSTER[loadout_index].health)+(25.0 if has("heart") else 0.0)
		"energy": return (125.0 if has("cell") else 100.0)+(20.0 if has("reserve") else 0.0)
		"regen": return 1.25 if has("flow") else 1.0
		"armor": return 0.85 if has("armor") else 1.0
		"impact": return 1.25 if has("impact") else 1.0
		"power": return 1.1 if has("power") else 1.0
		"melee": return 1.2 if has("edge") else 1.0
		"ranged": return 1.2 if has("fire") else 1.0
		"dodge_cost": return float(Characters.ROSTER[loadout_index].dodge_cost)*(0.75 if has("step") else 1.0)
		"dodge_cd": return float(Characters.ROSTER[loadout_index].dodge_cd)*(0.75 if has("step") else 1.0)
		"parry": return float(Characters.ROSTER[loadout_index].parry)+(0.08 if has("guard") else 0.0)
		"resonance": return 1.35 if has("echo") else 1.0
	return 1.0
func choices(boss_index: int) -> Array:
	var available = active_upgrades().filter(func(u): return not has(u.id))
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
	return {"weapon":loadout_index,"seed":seed_value,"boss":next_boss,"upgrades":upgrades.duplicate(),"difficulty":difficulty,"assist":assist,"assisted":assist or assisted,"score":score,"time":time,"hits":hits}
func restore(value: Dictionary) -> bool:
	if not value.get("boss") is float and not value.get("boss") is int: return false
	if int(value.boss)<0 or int(value.boss)>Encounters.last_index(): return false
	reset(int(number(value.get("difficulty",0))))
	loadout_index = Arsenal.valid_index(value.get("weapon",Arsenal.DEFAULT))
	seed_value = int(number(value.get("seed",1)))
	assisted = value.get("assisted",value.get("assist",false)) == true
	if value.get("upgrades") is Array:
		for id in value.upgrades:
			if id is String and UPGRADES.any(func(u): return u.id == id) and not has(id): upgrades.append(id)
	# Retire old parry upgrades without leaving an unusable choice in a saved build.
	if not CombatRules.PARRY_ENABLED and has("guard"):
		upgrades.erase("guard")
		for replacement in ["step","cell","heart","edge","fire","echo","siphon"]:
			if not has(replacement): upgrades.append(replacement); break
	score = maxi(0,int(number(value.get("score",0))))
	time = maxf(0,number(value.get("time",0)))
	hits = maxi(0,int(number(value.get("hits",0))))
	return true

static func number(value: Variant) -> float:
	if (value is int or value is float) and is_finite(float(value)): return float(value)
	return 0.0

static func active_upgrades() -> Array:
	return UPGRADES.filter(func(u): return CombatRules.PARRY_ENABLED or u.id != "guard")
