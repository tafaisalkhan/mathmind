extends Control

const PrivacyDialogScene = preload("res://scenes/privacy_dialog.tscn")

@onready var difficulty_dropdown: OptionButton = $Margin/VBox/Panel/Scroll/Content/DifficultyRow/DifficultyDropdown
@onready var settings_panel: PanelContainer = $Margin/VBox/Panel
@onready var back_button: Button = $Margin/VBox/Header/BackButton
@onready var music_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/MusicToggle
@onready var sfx_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/SfxToggle
@onready var multiply_dropdown: OptionButton = $Margin/VBox/Panel/Scroll/Content/MultiplyRow/MultiplyDropdown
@onready var divide_dropdown: OptionButton = $Margin/VBox/Panel/Scroll/Content/DivideRow/DivideDropdown
@onready var notification_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/NotificationToggle
@onready var privacy_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/PrivacyToggle
@onready var remove_ads_button: Button = $Margin/VBox/Panel/Scroll/Content/RemoveAdsButton
@onready var purchase_status: Label = $Margin/VBox/Panel/Scroll/Content/PurchaseStatus


func _ready() -> void:
	_apply_popup_style()
	difficulty_dropdown.select(GameState.difficulty_index)
	music_toggle.button_pressed = GameState.music_enabled
	sfx_toggle.button_pressed = GameState.sfx_enabled
	multiply_dropdown.select(0 if GameState.multiply_symbol == "×" else 1)
	divide_dropdown.select(0 if GameState.divide_symbol == "÷" else 1)
	notification_toggle.button_pressed = GameState.daily_notifications
	privacy_toggle.button_pressed = GameState.show_privacy_on_start
	_update_purchase_status()
	back_button.pressed.connect(_go_back)
	difficulty_dropdown.item_selected.connect(_on_difficulty_selected)
	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	multiply_dropdown.item_selected.connect(_on_multiply_selected)
	divide_dropdown.item_selected.connect(_on_divide_selected)
	notification_toggle.toggled.connect(_on_notifications_toggled)
	privacy_toggle.toggled.connect(_on_privacy_toggled)
	remove_ads_button.pressed.connect(_on_remove_ads_pressed)

func _apply_popup_style() -> void:
	for toggle in [music_toggle, sfx_toggle, notification_toggle, privacy_toggle]:
		toggle.add_theme_color_override("font_color", Color.BLACK)
		toggle.add_theme_color_override("font_hover_color", Color("#222222"))
		toggle.add_theme_color_override("font_pressed_color", Color.BLACK)
		toggle.add_theme_stylebox_override("normal", _button_style(Color("#fff8d9"), Color("#d7b348")))
		toggle.add_theme_stylebox_override("hover", _button_style(Color("#fffdf0"), Color("#f0c94d")))
		toggle.add_theme_stylebox_override("pressed", _pressed_button_style(Color("#f5edc8"), Color("#14865f")))
		toggle.add_theme_constant_override("outline_size", 1)
	for heading in [$Margin/VBox/Panel/Scroll/Content/DifficultyRow/Label, $Margin/VBox/Panel/Scroll/Content/MultiplyRow/Label, $Margin/VBox/Panel/Scroll/Content/DivideRow/Label]:
		heading.add_theme_color_override("font_color", Color.BLACK)
	_style_option_button(multiply_dropdown, Color("#36c98b"), Color("#087451"))
	_style_option_button(divide_dropdown, Color("#36c98b"), Color("#087451"))
	remove_ads_button.add_theme_stylebox_override("normal", _button_style(Color("#ff8a3d"), Color("#b94716")))
	remove_ads_button.add_theme_stylebox_override("hover", _button_style(Color("#ffa14f"), Color("#b94716")))
	remove_ads_button.add_theme_stylebox_override("pressed", _pressed_button_style(Color("#df6f2c"), Color("#8f3110")))
	remove_ads_button.add_theme_color_override("font_color", Color.WHITE)
	difficulty_dropdown.add_theme_stylebox_override("normal", _button_style(Color("#ffd65a"), Color("#c98112")))
	difficulty_dropdown.add_theme_stylebox_override("hover", _button_style(Color("#71dfbd"), Color("#167762")))
	difficulty_dropdown.add_theme_stylebox_override("pressed", _button_style(Color("#ffc83d"), Color("#c98112")))
	difficulty_dropdown.add_theme_color_override("font_color", Color("#35210e"))
	difficulty_dropdown.add_theme_color_override("font_hover_color", Color("#123f36"))
	var difficulty_popup := difficulty_dropdown.get_popup()
	difficulty_popup.add_theme_stylebox_override("panel", _button_style(Color("#fff4bd"), Color("#c98112")))
	difficulty_popup.add_theme_color_override("font_color", Color("#35210e"))
	difficulty_popup.add_theme_color_override("font_hover_color", Color.WHITE)
	difficulty_popup.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	difficulty_popup.add_theme_font_size_override("font_size", 20)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff1b8")
	panel_style.border_color = Color("#14865f")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel_style.shadow_color = Color(0.02, 0.08, 0.05, 0.65)
	panel_style.shadow_size = 18
	panel_style.shadow_offset = Vector2(0, 9)
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	back_button.add_theme_stylebox_override("normal", _button_style(Color("#e94f45"), Color("#8f211d")))
	back_button.add_theme_stylebox_override("hover", _button_style(Color("#ff665b"), Color("#8f211d")))
	back_button.add_theme_stylebox_override("pressed", _pressed_button_style(Color("#cc3932"), Color("#701613")))
	back_button.add_theme_color_override("font_color", Color.WHITE)
	back_button.add_theme_font_size_override("font_size", 28)
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2(0.92, 0.92)
	settings_panel.pivot_offset = settings_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _style_option_button(button: OptionButton, fill: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(fill, border))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.12), border))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#ffd65a"), Color("#c98112")))
	button.add_theme_color_override("font_color", Color("#073c2b"))
	button.add_theme_color_override("font_hover_color", Color("#073c2b"))
func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(5)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.02, 0.08, 0.05, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6)
	return style

func _pressed_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _button_style(fill, border)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style
func _go_back() -> void:
	if back_button.disabled:
		return
	back_button.disabled = true
	GameState.save_progress()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _on_difficulty_selected(index: int) -> void:
	if not GameState.set_difficulty(index):
		difficulty_dropdown.select(GameState.difficulty_index)
		difficulty_dropdown.tooltip_text = "Complete all 1,000 levels in the previous difficulty first."
		return
	difficulty_dropdown.tooltip_text = ""
func _on_music_toggled(enabled: bool) -> void:
	GameState.music_enabled = enabled
	AudioManager.set_music_enabled(enabled)
	GameState.save_progress()

func _on_sfx_toggled(enabled: bool) -> void:
	GameState.sfx_enabled = enabled
	GameState.save_progress()

func _on_multiply_selected(index: int) -> void:
	GameState.multiply_symbol = "×" if index == 0 else "*"
	GameState.save_progress()

func _on_divide_selected(index: int) -> void:
	GameState.divide_symbol = "÷" if index == 0 else "/"
	GameState.save_progress()

func _on_notifications_toggled(enabled: bool) -> void:
	GameState.daily_notifications = enabled
	GameState.save_progress()
	if enabled and OS.get_name() == "Android":
		OS.request_permissions()

func _on_privacy_toggled(enabled: bool) -> void:
	GameState.show_privacy_on_start = enabled
	GameState.save_progress()
	if enabled:
		var dialog := PrivacyDialogScene.instantiate()
		add_child(dialog)

func _on_remove_ads_pressed() -> void:
	if not GameState.ads_removed:
		purchase_status.text = "Connect Google Play Billing to complete purchase"

func _update_purchase_status() -> void:
	if GameState.ads_removed:
		remove_ads_button.text = "✓ ADS REMOVED"
		remove_ads_button.disabled = true
		purchase_status.text = "Thank you for supporting Math Mind!"
	else:
		purchase_status.text = "One-time purchase • Restore supported"
