extends Node

const BACKGROUND_MUSIC: AudioStream = preload("res://assets/sound/background_music.wav")
const COIN_SOUND: AudioStream = preload("res://assets/sound/coin_sound.wav")
const LEVEL_COMPLETE_SOUND: AudioStream = preload("res://assets/sound/level_complete.mp3")
const LEVEL_FAIL_SOUND: AudioStream = preload("res://assets/sound/level_fail.mp3")
const LEVEL_START_SOUND: AudioStream = preload("res://assets/sound/star_sound.mp3")
const RIGHT_ANSWER_SOUND: AudioStream = preload("res://assets/sound/right_answer.mp3")
const WRONG_ANSWER_SOUND: AudioStream = preload("res://assets/sound/wrong_answer.mp3")

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(sfx_player)
	music_player.volume_db = -18.0
	sfx_player.volume_db = -7.0
	music_player.stream = BACKGROUND_MUSIC

	music_player.finished.connect(_restart_music)
	if GameState.music_enabled:
		music_player.play()

func _restart_music() -> void:
	if GameState.music_enabled and is_instance_valid(music_player):
		music_player.call_deferred("play")
func set_music_enabled(enabled: bool) -> void:
	if enabled and not music_player.playing:
		music_player.play()
	elif not enabled:
		music_player.stop()

func pause_music() -> void:
	if is_instance_valid(music_player):
		music_player.stream_paused = true

func resume_music() -> void:
	if not GameState.music_enabled or not is_instance_valid(music_player):
		return
	if not music_player.playing:
		music_player.play()
	music_player.stream_paused = false

func play_place(correct: bool) -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = RIGHT_ANSWER_SOUND if correct else WRONG_ANSWER_SOUND
		sfx_player.play()

func play_level_start() -> void:
	pass

func play_star() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = LEVEL_START_SOUND
		sfx_player.play()

func play_coin() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = COIN_SOUND
		sfx_player.play()

func play_level_complete() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = LEVEL_COMPLETE_SOUND
		sfx_player.play()

func play_level_fail() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = LEVEL_FAIL_SOUND
		sfx_player.play()

func play_undo() -> void:
	pass

func play_hint() -> void:
	pass

func play_victory() -> void:
	play_level_complete()

func _make_music() -> AudioStreamWAV:
	return _make_sequence([261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 392.0], 0.34, true)

func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	return _make_sequence([frequency], duration, false)

func _make_sequence(notes: Array, note_duration: float, looped: bool) -> AudioStreamWAV:
	var rate: int = 44100
	var samples_per_note: int = int(rate * note_duration)
	var sample_count: int = samples_per_note * notes.size()
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var note_index: int = int(sample_index / samples_per_note)
		var local_sample: int = sample_index % samples_per_note
		var phase: float = TAU * float(notes[note_index]) * float(local_sample) / float(rate)
		var envelope: float = sin(PI * float(local_sample) / float(samples_per_note))
		var value: float = sin(phase) * 0.62 + sin(phase * 2.0) * 0.16
		bytes.encode_s16(sample_index * 2, int(value * envelope * 12000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream