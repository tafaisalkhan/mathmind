extends Control

const ChapterThemesScript = preload("res://scripts/chapter_themes.gd")
const PrivacyDialogScene = preload("res://scenes/privacy_dialog.tscn")

@onready var play_button: Button = $Margin/VBox/PlayButton
@onready var daily_button: Button = $Margin/VBox/DailyButton
@onready var settings_button: Button = $Margin/VBox/SettingsButton
@onready var chapter_label: Label = $Margin/VBox/ChapterPanel/ChapterLabel

func _ready() -> void:
	_apply_game_styles()
	play_button.pressed.connect(_start_play)
	daily_button.pressed.connect(_start_daily)
	settings_button.pressed.connect(_open_settings)
	chapter_label.text = "4 DIFFICULTIES  •  4,000 LEVELS"
	_start_idle_motion()
	if not GameState.privacy_accepted or GameState.show_privacy_on_start:
		_show_privacy_policy()

func _show_privacy_policy() -> void:
	var dialog := PrivacyDialogScene.instantiate()
	add_child(dialog)

func _start_play() -> void:
	call_deferred("_open_level_select")

func _open_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _start_daily() -> void:
	GameState.start_mode("daily")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _open_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _apply_game_styles() -> void:
	_style_button_3d(play_button, Color("#24bd68"), Color("#075f3e"), Color.WHITE)
	_style_button_3d(daily_button, Color("#ffd34f"), Color("#b96a0c"), Color("#35210e"))
	_style_button_3d(settings_button, Color("#67e4be"), Color("#116b58"), Color("#123f36"))
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.97, 0.86, 0.96)
	panel_style.border_color = Color("#f6d36b")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_color = Color(0.04, 0.1, 0.07, 0.55)
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(0, 7)
	$Margin/VBox/ChapterPanel.add_theme_stylebox_override("panel", panel_style)

func _style_button_3d(button: Button, fill: Color, dark: Color, text_color: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(fill, dark, 9, 7))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.12), dark, 11, 8))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.12), dark, 3, 2))
	button.add_theme_stylebox_override("focus", _button_style(fill, Color("#fff0a6"), 9, 7))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, text_color)
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.48))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 3)
	button.button_down.connect(_animate_button.bind(button, true))
	button.button_up.connect(_animate_button.bind(button, false))

func _button_style(fill: Color, border: Color, shadow_size: int, shadow_y: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(5)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.02, 0.08, 0.05, 0.62)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, shadow_y)
	style.anti_aliasing = true
	return style

func _animate_button(button: Button, pressed: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.97, 0.97) if pressed else Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func _start_idle_motion() -> void:
	var logo := $Margin/VBox/Logo
	var tween := create_tween().set_loops()
	tween.tween_property(logo, "modulate", Color(1.08, 1.08, 1.08, 1), 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo, "modulate", Color.WHITE, 1.1).set_trans(Tween.TRANS_SINE)
