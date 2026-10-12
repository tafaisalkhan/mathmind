extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(sfx_player)
	music_player.volume_db = -18.0
	sfx_player.volume_db = -7.0
	music_player.stream = _make_music()
	if OS.get_name() == "Android":
		music_player.finished.connect(_restart_android_music)
	if GameState.music_enabled:
		music_player.play()

func _restart_android_music() -> void:
	if GameState.music_enabled and is_instance_valid(music_player):
		music_player.call_deferred("play")
func set_music_enabled(enabled: bool) -> void:
	if enabled and not music_player.playing:
		music_player.play()
	elif not enabled:
		music_player.stop()

func play_place(correct: bool) -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = _make_tone(660.0 if correct else 190.0, 0.13)
		sfx_player.play()

func play_undo() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = _make_tone(330.0, 0.16)
		sfx_player.play()

func play_hint() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = _make_tone(880.0, 0.22)
		sfx_player.play()

func play_victory() -> void:
	if GameState.sfx_enabled:
		sfx_player.stream = _make_sequence([523.25, 659.25, 783.99, 1046.5], 0.18, false)
		sfx_player.play()

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
	if looped and OS.get_name() != "Android":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream