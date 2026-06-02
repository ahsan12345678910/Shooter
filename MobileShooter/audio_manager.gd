extends Node

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.stream = _create_powerup_collect_sound()


func play_powerup_collect() -> void:
	_player.stop()
	_player.play()


func _create_powerup_collect_sound() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false

	var mix_rate := 22050.0
	var duration := 0.14
	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / mix_rate
		var envelope := 1.0 - (t / duration)
		var freq := 660.0 + 520.0 * t
		var sample := sin(TAU * freq * t) * envelope * 0.45
		var sample_16 := int(clampf(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF

	wav.data = data
	return wav
