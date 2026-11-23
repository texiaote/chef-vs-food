extends Sprite2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	region_enabled = true
	centered = true
	z_index = -100


func sync_to(cam_pos: Vector2, view_size: Vector2) -> void:
	global_position = cam_pos
	var size := view_size + Vector2(48, 48)
	region_rect = Rect2(cam_pos - size * 0.5, size)
