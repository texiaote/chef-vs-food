class_name ThemeUtil
extends RefCounted

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/game_cjk.ttf")
	return _font


static func label(text: String, size: int = 14, color: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func panel_style(bg: Color = Color(0.05, 0.06, 0.09, 0.88)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.92, 0.95, 1.0, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


static func button_style(bg: Color) -> StyleBoxFlat:
	var style := panel_style(bg)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style


static func style_button(button: Button, bg: Color = Color(0.12, 0.18, 0.14, 0.94)) -> void:
	button.add_theme_font_override("font", font())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_stylebox_override("normal", button_style(bg))
	button.add_theme_stylebox_override("hover", button_style(bg.lightened(0.18)))
	button.add_theme_stylebox_override("pressed", button_style(bg.darkened(0.12)))
	button.add_theme_stylebox_override("focus", button_style(Color(0.22, 0.34, 0.24, 0.96)))


static func garden_background(parent: Node) -> TextureRect:
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.texture = load("res://assets/textures/ground.png")
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect
