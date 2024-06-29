extends DialogBase


func _on_button_close_pressed():
	dialog_result = 0
	close_dialog()


func prepare_show(init_data) -> void:
	$Target1/Label.text = init_data["0text"]
	$Target2/Label.text = init_data["1text"]
	$Target3/Label.text = init_data["2text"]

	set_texture_offset($Target1/TextureRect.texture, init_data["0offset"])
	set_texture_offset($Target2/TextureRect.texture, init_data["1offset"])
	set_texture_offset($Target3/TextureRect.texture, init_data["2offset"])


func set_texture_offset(texture: AtlasTexture, offset: Vector2) -> void:
	var rect := texture.region
	rect.position = offset
	texture.region = rect