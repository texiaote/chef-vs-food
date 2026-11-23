class_name Hud
extends CanvasLayer

var _level: Label
var _fill: ColorRect
var _fill_width: float = 108.0
var _timer: Label
var _kills: Label
var _banner: Label
var _banner_time: float = 0.0


func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var left := Panel.new()
	left.anchor_left = 0.0
	left.anchor_right = 0.0
	left.offset_left = 8
	left.offset_top = 8
	left.offset_right = 214
	left.offset_bottom = 36
	left.add_theme_stylebox_override("panel", ThemeUtil.panel_style())
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(row)

	_level = ThemeUtil.label("LVL 1", 14)
	_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_level)

	var bar_back := ColorRect.new()
	bar_back.custom_minimum_size = Vector2(_fill_width, 10)
	bar_back.color = Color(0.05, 0.08, 0.14, 1)
	bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar_back)
	_fill = ColorRect.new()
	_fill.color = Color(0.25, 0.62, 1.0, 1)
	_fill.size = Vector2(_fill_width, 10)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_back.add_child(_fill)

	var timer_panel := Panel.new()
	timer_panel.anchor_left = 0.5
	timer_panel.anchor_right = 0.5
	timer_panel.offset_left = -46
	timer_panel.offset_right = 46
	timer_panel.offset_top = 8
	timer_panel.offset_bottom = 36
	timer_panel.add_theme_stylebox_override("panel", ThemeUtil.panel_style(Color(0.04, 0.05, 0.08, 0.92)))
	timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(timer_panel)
	_timer = ThemeUtil.label("00:00", 16)
	_timer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_panel.add_child(_timer)

	var kill_panel := Panel.new()
	kill_panel.anchor_left = 1.0
	kill_panel.anchor_right = 1.0
	kill_panel.offset_left = -158
	kill_panel.offset_right = -8
	kill_panel.offset_top = 8
	kill_panel.offset_bottom = 36
	kill_panel.add_theme_stylebox_override("panel", ThemeUtil.panel_style())
	kill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(kill_panel)
	var kill_row := HBoxContainer.new()
	kill_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	kill_row.alignment = BoxContainer.ALIGNMENT_CENTER
	kill_row.add_theme_constant_override("separation", 6)
	kill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_panel.add_child(kill_row)
	var skull := TextureRect.new()
	skull.texture = load("res://assets/textures/skull.png")
	skull.custom_minimum_size = Vector2(14, 14)
	skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_row.add_child(skull)
	_kills = ThemeUtil.label("KILLS 0", 14)
	_kills.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kill_row.add_child(_kills)

	_banner = ThemeUtil.label("", 16, Color(1.0, 0.92, 0.7))
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.offset_left = -160
	_banner.offset_right = 160
	_banner.offset_top = 44
	_banner.offset_bottom = 68
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.visible = false
	root.add_child(_banner)


func _process(delta: float) -> void:
	var battle := get_parent()
	if battle == null or battle.balance == null:
		return
	_level.text = "LVL %d" % int(battle.level)
	var need := int(battle.balance.xp_to_next(int(battle.level)))
	var ratio := 0.0 if need <= 0 else clampf(float(battle.xp) / float(need), 0.0, 1.0)
	_fill.size = Vector2(_fill_width * ratio, 10)
	_timer.text = _format_time(float(battle.run_time))
	_kills.text = "KILLS %d" % int(battle.kills)
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time <= 0.0:
			_banner.visible = false


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_time = 3.2


func _format_time(time_sec: float) -> String:
	var whole := maxi(int(floor(time_sec)), 0)
	return "%02d:%02d" % [int(whole / 60.0), whole % 60]
