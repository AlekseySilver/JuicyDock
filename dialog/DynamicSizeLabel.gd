extends Label

@export var font_scale: float = 0.5

func _ready():
	if label_settings:
		label_settings.font_size = int(get_rect().size.y * font_scale)


