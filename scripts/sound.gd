extends Node
## Original generated effects. No external tracks or copyrighted samples.
var voices: Array[AudioStreamPlayer] = []
var enabled := true
func _ready() -> void:
	for i in 10:
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
func tone(freq: float, duration: float = 0.09, gain: float = 0.13) -> void:
	if not enabled: return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes = PackedByteArray()
	bytes.resize(int(duration*22050)*2)
	for i in bytes.size()/2:
		var t = float(i)/22050.0
		var envelope = pow(1.0-t/duration,2.0)*minf(t*500.0,1.0)
		var value = int(sin(TAU*freq*t)*envelope*gain*32760)
		bytes.encode_s16(i*2,value)
	stream.data = bytes
	for voice in voices:
		if not voice.playing:
			voice.stream = stream
			voice.play()
			return
