extends Control

var _weapon_row: HBoxContainer
var _hint: Label
var _buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ThemeUtil.garden_background(self)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	var title := ThemeUtil.label("厨师大战食材怪", 28, Color(1.0, 0.96, 0.84))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := ThemeUtil.label("Chef vs Food", 14, Color(0.9, 0.95, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var version := ThemeUtil.label("v0.1", 11, Color(0.8, 0.86, 0.8))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(version)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "开始游戏"
	start.custom_minimum_size = Vector2(180, 32)
	ThemeUtil.style_button(start)
	start.pressed.connect(_on_start)
	column.add_child(start)

	var quit := Button.new()
	quit.name = "QuitButton"
	quit.text = "退出"
	quit.custom_minimum_size = Vector2(180, 28)
	ThemeUtil.style_button(quit, Color(0.18, 0.12, 0.12, 0.94))
	quit.pressed.connect(_on_quit)
	column.add_child(quit)

	_hint = ThemeUtil.label("", 11, Color(1, 0.95, 0.8))
	_hint.name = "UnlockHint"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(420, 0)
	column.add_child(_hint)

	_weapon_row = HBoxContainer.new()
	_weapon_row.name = "WeaponRow"
	_weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_weapon_row.add_theme_constant_override("separation", 6)
	column.add_child(_weapon_row)
	_build_weapons()
	_refresh()
	start.grab_focus()


func _build_weapons() -> void:
	for id in Game.WEAPON_ORDER:
		var data: WeaponData = Game.weapons.get(String(id))
		var button := Button.new()
		button.toggle_mode = false
		button.custom_minimum_size = Vector2(86, 64)
		var label: String = data.display_name if data != null else String(id)
		button.text = label.split(" ")[0]
		if data != null and data.texture != null:
			button.icon = data.texture
			button.expand_icon = true
		button.add_theme_font_override("font", ThemeUtil.font())
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_on_weapon.bind(String(id)))
		_weapon_row.add_child(button)
		_buttons[String(id)] = button


func _refresh() -> void:
	var unlocked := SaveManager.cake_unlocked
	_weapon_row.visible = unlocked
	if unlocked:
		_hint.text = "初始武器（击败蛋糕后已解锁）"
	else:
		_hint.text = "初始武器：飞刀。击败巨型生日蛋糕后可选任意武器开局。"
	for id in _buttons.keys():
		var button: Button = _buttons[id]
		var selected: bool = String(id) == SaveManager.starting_weapon_id()
		var bg := Color(0.36, 0.28, 0.12, 0.96) if selected else Color(0.12, 0.16, 0.14, 0.94)
		ThemeUtil.style_button(button, bg)
		button.add_theme_font_size_override("font_size", 11)


func _on_weapon(id: String) -> void:
	SaveManager.set_start_weapon(id)
	AudioManager.play("ui_confirm")
	_refresh()


func _on_start() -> void:
	AudioManager.play("ui_confirm")
	Game.auto_play = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	Game.go_battle()


func _on_quit() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_quit()
