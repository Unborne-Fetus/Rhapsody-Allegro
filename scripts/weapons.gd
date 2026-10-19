extends RefCounted
## A set changes both attacks. Cadence is attacks/second, not projectile velocity.
const SETS := [
	{"id":"breaker","name":"BREAKER","role":"SLOW / CLOSE / HEAVY","description":"Hammer + Faultline slam","color":"ef9064","shape":"hammer",
	"melee_damage":[96.0,108.0,150.0],"melee_cooldown":[0.80,0.88,1.15],"windup":[0.22,0.24,0.32],"melee_range":[110.0,115.0,135.0],"arc":1.10,"dash_damage":126.0,"dash_range":155.0,"stagger":26.0,"resonance":22.0,"energy_return":26.0,"flash":0.22,
	"cost":30.0,"cooldown":2.0,"damage":115.0,"speed":0.0,"range":180.0,"count":0,"spread":0.0,"radius":0.0},
	{"id":"flurry","name":"FLURRY","role":"VERY FAST / CLOSE / LIGHT","description":"Twin knives + Razorstep","color":"74ead5","shape":"knives",
	"melee_damage":[11.0,12.0,18.0],"melee_cooldown":[0.105,0.105,0.17],"windup":[0.015,0.015,0.03],"melee_range":[88.0,94.0,106.0],"arc":0.90,"dash_damage":19.0,"dash_range":128.0,"stagger":3.5,"resonance":2.8,"energy_return":4.0,"flash":0.075,
	"cost":22.0,"cooldown":0.9,"damage":32.0,"speed":0.0,"range":145.0,"count":0,"spread":0.0,"radius":0.0},
	{"id":"cadence","name":"CADENCE","role":"BALANCED / MID / STRONG","description":"Saber + Crescent Guard","color":"e8c575","shape":"saber",
	"melee_damage":[34.0,38.0,60.0],"melee_cooldown":[0.30,0.32,0.48],"windup":[0.06,0.065,0.11],"melee_range":[150.0,160.0,175.0],"arc":0.85,"dash_damage":49.0,"dash_range":195.0,"stagger":10.0,"resonance":8.0,"energy_return":13.0,"flash":0.15,
	"cost":22.0,"cooldown":1.2,"damage":48.0,"speed":0.0,"range":200.0,"count":0,"spread":0.0,"radius":0.0},
	{"id":"horizon","name":"HORIZON","role":"MODERATE / LONG / LIGHT","description":"Light spear + marksman rifle","color":"c3b1fa","shape":"spear",
	"melee_damage":[18.0,20.0,28.0],"melee_cooldown":[0.36,0.38,0.50],"windup":[0.09,0.10,0.13],"melee_range":[215.0,225.0,240.0],"arc":0.35,"dash_damage":28.0,"dash_range":260.0,"stagger":5.0,"resonance":4.0,"energy_return":7.0,"flash":0.17,
	"cost":10.0,"cooldown":0.44,"damage":12.0,"speed":1050.0,"range":950.0,"count":1,"spread":0.0,"radius":3.5}
]
const DEFAULT := 2
static func valid_index(value: Variant) -> int:
	if not (value is int or value is float) or not is_finite(float(value)): return DEFAULT
	return clampi(int(value),0,SETS.size()-1)
