extends Node

const SAVE_PATH := "user://math_mind_progress.cfg"
const SAVE_VERSION := 2

var highest_level: int = 1
var highest_levels: Array[int] = [1, 0, 0, 0]
var last_selected_levels: Array[int] = [1, 1, 1, 1]
var coins: int = 0
var total_stars: int = 0
var win_streak: int = 0
var games_played: int = 0
var selected_theme: String = "Classic"
var game_mode: String = "continue"
var requested_level: int = 1
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var music_enabled: bool = true
var sfx_enabled: bool = true
var multiply_symbol: String = "×"
var divide_symbol: String = "÷"
var ads_removed: bool = false
var daily_notifications: bool = true
var privacy_accepted: bool = false
var show_privacy_on_start: bool = false
var difficulty_index: int = 0

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		save_progress()
		return
	var saved_version := int(config.get_value("progress", "save_version", 0))
	if saved_version < SAVE_VERSION:
		highest_level = 1
		total_stars = 0
		win_streak = 0
		games_played = 0
		save_progress()
		return
	highest_level = int(config.get_value("progress", "highest_level", 1))
	coins = int(config.get_value("progress", "coins", 0))
	total_stars = int(config.get_value("progress", "total_stars", 0))
	win_streak = int(config.get_value("progress", "win_streak", 0))
	games_played = int(config.get_value("progress", "games_played", 0))
	selected_theme = str(config.get_value("progress", "theme", "Classic"))
	music_volume = float(config.get_value("settings", "music_volume", 0.8))
	sfx_volume = float(config.get_value("settings", "sfx_volume", 0.9))
	music_enabled = bool(config.get_value("settings", "music_enabled", true))
	sfx_enabled = bool(config.get_value("settings", "sfx_enabled", true))
	multiply_symbol = str(config.get_value("settings", "multiply_symbol", "×"))
	divide_symbol = str(config.get_value("settings", "divide_symbol", "÷"))
	ads_removed = bool(config.get_value("settings", "ads_removed", false))
	daily_notifications = bool(config.get_value("settings", "daily_notifications", true))
	privacy_accepted = bool(config.get_value("privacy", "accepted", false))
	show_privacy_on_start = bool(config.get_value("privacy", "show_on_start", false))
	difficulty_index = clampi(int(config.get_value("settings", "difficulty_index", 0)), 0, 3)
	highest_levels = [
		int(config.get_value("progress", "highest_easy", highest_level)),
		int(config.get_value("progress", "highest_medium", 0)),
		int(config.get_value("progress", "highest_hard", 0)),
		int(config.get_value("progress", "highest_expert", 0))
	]
	last_selected_levels = [
		int(config.get_value("progress", "last_easy", 1)),
		int(config.get_value("progress", "last_medium", 1)),
		int(config.get_value("progress", "last_hard", 1)),
		int(config.get_value("progress", "last_expert", 1))
	]
	if not is_difficulty_unlocked(difficulty_index):
		difficulty_index = 0
	highest_level = maxi(1, highest_levels[difficulty_index])
	requested_level = clampi(last_selected_levels[difficulty_index], 1, mini(highest_level, 1000))

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "save_version", SAVE_VERSION)
	highest_levels[difficulty_index] = maxi(highest_levels[difficulty_index], highest_level)
	config.set_value("progress", "highest_level", highest_level)
	config.set_value("progress", "highest_easy", highest_levels[0])
	config.set_value("progress", "highest_medium", highest_levels[1])
	config.set_value("progress", "highest_hard", highest_levels[2])
	config.set_value("progress", "highest_expert", highest_levels[3])
	config.set_value("progress", "last_easy", last_selected_levels[0])
	config.set_value("progress", "last_medium", last_selected_levels[1])
	config.set_value("progress", "last_hard", last_selected_levels[2])
	config.set_value("progress", "last_expert", last_selected_levels[3])
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "total_stars", total_stars)
	config.set_value("progress", "win_streak", win_streak)
	config.set_value("progress", "games_played", games_played)
	config.set_value("progress", "theme", selected_theme)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "music_enabled", music_enabled)
	config.set_value("settings", "sfx_enabled", sfx_enabled)
	config.set_value("settings", "multiply_symbol", multiply_symbol)
	config.set_value("settings", "divide_symbol", divide_symbol)
	config.set_value("settings", "ads_removed", ads_removed)
	config.set_value("settings", "daily_notifications", daily_notifications)
	config.set_value("privacy", "accepted", privacy_accepted)
	config.set_value("privacy", "show_on_start", show_privacy_on_start)
	config.set_value("settings", "difficulty_index", difficulty_index)
	config.save(SAVE_PATH)

func unlocked_chapter() -> int:
	return maxi(1, int((highest_level - 1) / 10) + 1)

func daily_level() -> int:
	var date := Time.get_date_dict_from_system()
	return 1000 + int(date.year) * 372 + int(date.month) * 31 + int(date.day)

func start_mode(mode: String) -> void:
	game_mode = mode
	match mode:
		"daily": requested_level = daily_level()
		"endless": requested_level = maxi(highest_level, 11)
		_: requested_level = clampi(last_selected_levels[difficulty_index], 1, mini(highest_level, 1000))

func start_game_type(type_index: int) -> void:
	game_mode = "selected"
	var start_levels := [1, 101, 201, 301]
	requested_level = start_levels[clampi(type_index, 0, start_levels.size() - 1)]
func start_selected_level(level: int) -> void:
	game_mode = "selected"
	if level > highest_level:
		return
	requested_level = clampi(level, 1, 1000)
	last_selected_levels[difficulty_index] = requested_level
	save_progress()
func is_difficulty_unlocked(_index: int) -> bool:
	return true

func set_difficulty(index: int) -> bool:
	index = clampi(index, 0, 3)
	if not is_difficulty_unlocked(index):
		return false
	highest_levels[difficulty_index] = maxi(highest_levels[difficulty_index], highest_level)
	difficulty_index = index
	highest_level = maxi(1, highest_levels[index])
	requested_level = clampi(last_selected_levels[index], 1, mini(highest_level, 1000))
	save_progress()
	return true

func remember_level(level: int) -> void:
	requested_level = clampi(level, 1, 1000)
	last_selected_levels[difficulty_index] = requested_level
	save_progress()

func register_win(level: int, stars: int, reward: int) -> void:
	# Only the next sequential level can be unlocked by a win.
	if level <= highest_level:
		highest_level = maxi(highest_level, level + 1)
		highest_levels[difficulty_index] = highest_level
	coins += reward
	total_stars += stars
	win_streak += 1
	games_played += 1
	save_progress()
