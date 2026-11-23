extends Control

var title_label: Label
var time_label: Label
var level_label: Label
var kills_label: Label
var cake_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ThemeUtil.garden_background(self)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.4)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeUtil.panel_style(Color(0.05, 0.07, 0.08, 0.92)))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.custom_minimum_size = Vector2(280, 0)
	panel.add_child(column)

	var result: Dictionary = Game.last_result
	var won := bool(result.get("victory", false))
	title_label = ThemeUtil.label("胜利 Victory" if won else "失败 Defeat", 24, Color(1.0, 0.92, 0.55) if won else Color(1.0, 0.55, 0.5))
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)

	time_label = ThemeUtil.label("存活时间  %s" % _format_time(float(result.get("time", 0.0))), 16)
	time_label.name = "TimeLabel"
	column.add_child(time_label)
	level_label = ThemeUtil.label("等级  %d" % int(result.get("level", 1)), 16)
	level_label.name = "LevelLabel"
	column.add_child(level_label)
	kills_label = ThemeUtil.label("击杀  %d" % int(result.get("kills", 0)), 16)
	kills_label.name = "KillsLabel"
	column.add_child(kills_label)
	var cake := "已击败" if bool(result.get("cake_killed", false)) else "未击败"
	cake_label = ThemeUtil.label("巨型生日蛋糕  %s" % cake, 16)
	cake_label.name = "CakeLabel"
	column.add_child(cake_label)

	var again := Button.new()
	again.text = "再来一局"
	ThemeUtil.style_button(again)
	again.pressed.connect(_on_again)
	column.add_child(again)
	var menu := Button.new()
	menu.text = "返回主菜单"
	ThemeUtil.style_button(menu)
	menu.pressed.connect(_on_menu)
	column.add_child(menu)
	again.grab_focus()


func _format_time(time_sec: float) -> String:
	var whole := maxi(int(floor(time_sec)), 0)
	return "%02d:%02d" % [int(whole / 60.0), whole % 60]


func _on_again() -> void:
	AudioManager.play("ui_confirm")
	Game.auto_play = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	Game.go_battle()


func _on_menu() -> void:
	AudioManager.play("ui_confirm")
	Game.go_menu()
