extends RefCounted
## Versioned local profile. Browser exports use Godot's IndexedDB-backed user://.
const Arsenal = preload("res://scripts/weapons.gd")
const PATH := "user://profile.json"
var path := PATH
var data: Dictionary = {"version":1,"unlocked":0,"best":{},"volume":0.6,"shake":true,"assist":false,"difficulty":0,"weapon":2,"tutorial_complete":false,"flashes":true,"checkpoint":{}}
func load_profile() -> void:
	if not FileAccess.file_exists(path): return
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return
	var parsed = parser.data
	if parsed is Dictionary and parsed.get("version") == 1:
		for key in data:
			if parsed.has(key) and typeof(parsed[key]) == typeof(data[key]): data[key] = parsed[key]
		data.unlocked = int(parsed.get("unlocked",0)) if parsed.get("unlocked",0) is float or parsed.get("unlocked",0) is int else 0
		var valid_best: Dictionary = {}
		for key in data.best:
			var record = data.best[key]
			if record is Dictionary and record.get("time") is float and (record.get("hits") is float or record.get("hits") is int):
				valid_best[key] = {"time":maxf(0,record.time),"hits":maxi(0,int(record.hits))}
		data.best = valid_best
		data.unlocked = clampi(int(data.unlocked),0,2)
		data.difficulty = clampi(int(parsed.get("difficulty",0)),0,2) if parsed.get("difficulty",0) is float or parsed.get("difficulty",0) is int else 0
		data.weapon = Arsenal.valid_index(parsed.get("weapon",Arsenal.DEFAULT))
		data.volume = clampf(float(data.volume),0,1)
func save_profile() -> void:
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		DirAccess.rename_absolute(path+".tmp",path)
func record_key(index: int,difficulty: int = 0,assisted: Variant = null) -> String:
	return str(index) + ("_d"+str(difficulty) if difficulty>0 else "") + ("_assist" if (bool(data.assist) if assisted == null else bool(assisted)) else "")
func record_clear(index: int, seconds: float, hits: int,difficulty: int = 0,assisted: Variant = null) -> void:
	data.unlocked = mini(2,maxi(int(data.unlocked),index+1))
	var key = record_key(index,difficulty,assisted)
	if not data.best.has(key) or seconds < float(data.best[key].time):
		data.best[key] = {"time":seconds,"hits":hits}
	save_profile()
