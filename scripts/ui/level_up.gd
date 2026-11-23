class_name LevelUpUI
extends CanvasLayer

signal picked(index: int)

var open: bool = false
var _cards: HBoxContainer
var _dim: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var root := Control.new()
	root.name = "Root"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_dim = ColorRect.new()
	_dim.process_mode = Node.PROCESS_MODE_ALWAYS
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.visible = false
	root.add_child(_dim)

	var center := CenterContainer.new()
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var column := VBoxContainer.new()
	column.process_mode = Node.PROCESS_MODE_ALWAYS
	column.add_theme_constant_override("separation", 8)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)

	var title := ThemeUtil.label("升级！选一个", 20, Color(1.0, 0.95, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var hint := ThemeUtil.label("键盘 1 / 2 / 3    手柄 A / B / X", 11, Color(0.85, 0.88, 0.92))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	_cards = HBoxContainer.new()
	_cards.process_mode = Node.PROCESS_MODE_ALWAYS
	_cards.add_theme_constant_override("separation", 8)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_cards)
	visible = false


func present(choices: Array) -> void:
	_clear_cards()
	open = true
	visible = true
	_dim.visible = true
	for i in choices.size():
		_cards.add_child(_make_card(choices[i], i))


func dismiss() -> void:
	open = false
	visible = false
	if _dim != null:
		_dim.visible = false
	_clear_cards()


func _make_card(choice: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.custom_minimum_size = Vector2(188, 176)
	button.focus_mode = Control.FOCUS_ALL
	ThemeUtil.style_button(button, _tag_color(str(choice.get("tag", ""))))
	button.pressed.connect(_emit_pick.bind(index))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	button.add_child(box)
	var tag := ThemeUtil.label(str(choice.get("tag", "")), 11, Color(1.0, 0.9, 0.55))
	box.add_child(tag)
	var icon := TextureRect.new()
	icon.texture = choice.get("texture")
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var title := ThemeUtil.label(str(choice.get("title", "")), 13)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var body := ThemeUtil.label(str(choice.get("body", "")), 11, Color(0.9, 0.92, 0.95))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(168, 0)
	box.add_child(body)
	return button


func _tag_color(tag: String) -> Color:
	match tag:
		"进化":
			return Color(0.28, 0.16, 0.34, 0.96)
		"新武器":
			return Color(0.28, 0.2, 0.1, 0.96)
		"被动":
			return Color(0.1, 0.22, 0.18, 0.96)
		"恢复":
			return Color(0.28, 0.14, 0.18, 0.96)
		_:
			return Color(0.14, 0.16, 0.22, 0.96)


func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	var index := -1
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				index = 0
			KEY_2, KEY_KP_2:
				index = 1
			KEY_3, KEY_KP_3:
				index = 2
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A:
				index = 0
			JOY_BUTTON_B:
				index = 1
			JOY_BUTTON_X:
				index = 2
	if index >= 0:
		_emit_pick(index)
		get_viewport().set_input_as_handled()


func _emit_pick(index: int) -> void:
	if not open:
		return
	open = false
	picked.emit(index)


func _clear_cards() -> void:
	if _cards == null:
		return
	for child in _cards.get_children():
		child.queue_free()
