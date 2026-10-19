extends Node
## Original generated effects. No external tracks or copyrighted samples.
var voices: Array[AudioStreamPlayer] = []
var enabled := true
# A drum/bass hit can repeat dozens of times each second. Synthesis on *every*
# call used to allocate PCM buffers and recalculate thousands of sine samples.
# Cache the short deterministic cues and never synthesize if every voice is busy.
const MAX_CACHED_TONES := 96
var tone_cache: Dictionary = {}
func _ready() -> void:
	setup_music()
	for i in 10:
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func tone(freq: float, duration: float = 0.09, gain: float = 0.13) -> void:
	if not enabled: return
	var available: AudioStreamPlayer = null
	for voice in voices:
		if not voice.playing:
			available = voice
			break
	if available == null: return
	var frequency := maxi(1,roundi(freq))
	var millis := maxi(1,roundi(duration*1000.0))
	var amplitude := clampi(roundi(gain*1000.0),0,1000)
	var key := Vector3i(frequency,millis,amplitude)
	if not tone_cache.has(key):
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var seconds := float(millis)/1000.0
		var samples := maxi(1,roundi(seconds*22050.0))
		var bytes := PackedByteArray()
		bytes.resize(samples*2)
		for i in samples:
			var t := float(i)/22050.0
			var envelope := pow(maxf(0.0,1.0-t/seconds),2.0)*minf(t*500.0,1.0)
			var value := int(sin(TAU*float(frequency)*t)*envelope*float(amplitude)*32.76)
			bytes.encode_s16(i*2,value)
		stream.data = bytes
		if tone_cache.size()>=MAX_CACHED_TONES:
			tone_cache.clear()
		tone_cache[key] = stream
	available.stream = tone_cache[key]
	available.play()

var music: AudioStreamPlayer
var intensity: AudioStreamPlayer
var music_index := -1
var music_phase := 0
var music_enabled := true
var streams: Dictionary = {}
func setup_music() -> void:
	music = AudioStreamPlayer.new(); intensity = AudioStreamPlayer.new()
	add_child(music); add_child(intensity)
	music.volume_db = -11; intensity.volume_db = -60
func music_stream(index: int,layer: bool) -> AudioStreamOggVorbis:
	var path = "res://assets/music/boss-%02d%s.ogg" % [index,"-intensity" if layer else ""]
	if not streams.has(path):
		var stream = load(path) as AudioStreamOggVorbis
		stream.loop = true
		streams[path] = stream
	return streams[path]
func sync_music(index: int,phase: int,active: bool,paused: bool,allowed: bool,delta: float = .016) -> void:
	if not is_instance_valid(music): return
	music_enabled = allowed
	if not enabled or not allowed or (not active and not paused):
		music.stop(); intensity.stop(); music_index = -1; return
	if active and music_index != index:
		music_index = index; intensity.volume_db = -60
		music.stream = music_stream(index,false); intensity.stream = music_stream(index,true)
		music.play(); intensity.play()
	music.stream_paused = paused; intensity.stream_paused = paused
	music_phase = clampi(phase,0,2)
	var target = [-60.0,-18.0,-11.0][music_phase]
	intensity.volume_db = move_toward(intensity.volume_db,target,delta*48)
