extends Node

const MUSIC_PATH = "res://background_music.wav"
const SFX_SHOOT = "res://sfx_shoot.wav"
const SFX_ENEMY_HIT = "res://sfx_enemy_hit.wav"
const SFX_EXPLOSION = "res://sfx_explosion.wav"
const SFX_PLAYER_HIT = "res://sfx_player_hit.wav"
const SFX_POWERUP = "res://sfx_powerup.wav"
const SFX_BOSS_APPEAR = "res://sfx_boss_appear.wav"
const SFX_GAME_OVER = "res://sfx_game_over.wav"
const SFX_LEVEL_UP = "res://sfx_level_up.wav"

const MUSIC_VOL_KEY = "music_volume"
const SFX_VOL_KEY = "sfx_volume"
const SETTINGS_PATH = "user://settings.cfg"

var music_volume_db: float = -6.0
var sfx_volume_db: float = 0.0

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
const POOL_SIZE = 6


func _ready() -> void:
	_load_settings()
	_music = _make_player("Music", music_volume_db)
	_music.stream = _load_stream(MUSIC_PATH)
	if _music.stream and _music.stream is AudioStreamWAV:
		(_music.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	for i in POOL_SIZE:
		var p := _make_player("SFX_%d" % i, sfx_volume_db)
		_sfx_pool.append(p)


func play_music() -> void:
	if not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()


func set_music_paused(paused: bool) -> void:
	_music.stream_paused = paused


func play_shoot() -> void:
	_play_sfx(SFX_SHOOT)


func play_player_hit() -> void:
	_play_sfx(SFX_PLAYER_HIT)


func play_powerup_collect() -> void:
	_play_sfx(SFX_POWERUP)


func play_enemy_hit() -> void:
	_play_sfx(SFX_ENEMY_HIT)


func play_explosion() -> void:
	_play_sfx(SFX_EXPLOSION)


func play_boss_appear() -> void:
	_play_sfx(SFX_BOSS_APPEAR)


func play_game_over() -> void:
	_play_sfx(SFX_GAME_OVER)


func play_level_up() -> void:
	_play_sfx(SFX_LEVEL_UP)


func set_music_volume(linear: float) -> void:
	music_volume_db = linear_to_db(clampf(linear, 0.001, 1.0))
	_music.volume_db = music_volume_db
	_save_settings()


func set_sfx_volume(linear: float) -> void:
	sfx_volume_db = linear_to_db(clampf(linear, 0.001, 1.0))
	for p in _sfx_pool:
		p.volume_db = sfx_volume_db
	_save_settings()


func get_music_linear() -> float:
	return db_to_linear(music_volume_db)


func get_sfx_linear() -> float:
	return db_to_linear(sfx_volume_db)


func _play_sfx(path: String) -> void:
	var p := _sfx_pool[_pool_idx % POOL_SIZE]
	_pool_idx += 1
	var stream := _load_stream(path)
	if stream:
		p.stream = stream
		p.play()


func _make_player(n: String, vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = n
	p.volume_db = vol
	add_child(p)
	return p


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	push_warning("AudioManager: missing file " + path)
	return null


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume_db = float(cfg.get_value("audio", MUSIC_VOL_KEY, -6.0))
	sfx_volume_db = float(cfg.get_value("audio", SFX_VOL_KEY, 0.0))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", MUSIC_VOL_KEY, music_volume_db)
	cfg.set_value("audio", SFX_VOL_KEY, sfx_volume_db)
	cfg.save(SETTINGS_PATH)
