extends Node

var _music_player: AudioStreamPlayer
var _pickup_player: AudioStreamPlayer
var _shoot_player: AudioStreamPlayer
var _hit_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = _make_player("Music")
	_pickup_player = _make_player("Pickup")
	_shoot_player = _make_player("Shoot")
	_hit_player = _make_player("Hit")

	_pickup_player.stream = _create_powerup_collect_sound()
	_shoot_player.stream = _create_shoot_sound()
	_hit_player.stream = _create_player_hit_sound()
	_music_player.stream = _create_music_loop()
	_music_player.volume_db = -10.0
	_shoot_player.volume_db = -8.0
	_hit_player.volume_db = -4.0
	_pickup_player.volume_db = -6.0


func play_music() -> void:
	if _music_player.playing:
		return
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_powerup_collect() -> void:
	_pickup_player.stop()
	_pickup_player.play()


func play_shoot() -> void:
	_shoot_player.stop()
	_shoot_player.play()


func play_player_hit() -> void:
	_hit_player.stop()
	_hit_player.play()


func _make_player(name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = name
	add_child(player)
	return player


func _create_tone_stream(
	duration: float,
	freq_start: float,
	freq_end: float,
	volume: float,
	mix_rate: int = 22050
) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false

	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / float(mix_rate)
		var blend := t / duration if duration > 0.0 else 1.0
		var freq := lerpf(freq_start, freq_end, blend)
		var envelope := 1.0 - blend
		var sample := sin(TAU * freq * t) * envelope * volume
		var sample_16 := int(clampf(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF

	wav.data = data
	return wav


func _create_powerup_collect_sound() -> AudioStreamWAV:
	return _create_tone_stream(0.14, 660.0, 1180.0, 0.45)


func _create_shoot_sound() -> AudioStreamWAV:
	return _create_tone_stream(0.07, 920.0, 420.0, 0.32)


func _create_player_hit_sound() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false

	var mix_rate := 22050.0
	var duration := 0.28
	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / mix_rate
		var envelope := 1.0 - (t / duration)
		var noise := randf_range(-1.0, 1.0)
		var tone := sin(TAU * 110.0 * t) * 0.55
		var sample := (noise * 0.35 + tone) * envelope * 0.5
		var sample_16 := int(clampf(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF

	wav.data = data
	return wav


func _create_music_loop() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var mix_rate := 22050.0
	var duration := 4.0
	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var notes: PackedFloat32Array = PackedFloat32Array([0.0, 3.0, 5.0, 7.0, 5.0, 3.0, 0.0, -2.0])
	var base_freq := 130.0

	for i in sample_count:
		var t := float(i) / mix_rate
		var beat := int(t * 2.0) % notes.size()
		var note := notes[beat]
		var freq := base_freq * pow(2.0, note / 12.0)
		var sample := sin(TAU * freq * t) * 0.12
		sample += sin(TAU * freq * 2.0 * t) * 0.04
		sample += sin(TAU * 55.0 * t) * 0.06
		var sample_16 := int(clampf(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF

	wav.data = data
	return wav
