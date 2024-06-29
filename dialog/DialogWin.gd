extends DialogBase


func prepare_show(init_data) -> void:
	$Target1/Label.text = init_data["0text"]
	$Target2/Label.text = init_data["1text"]
	$Target3/Label.text = init_data["2text"]

	set_texture_offset($Target1/TextureRect.texture, init_data["0offset"])
	set_texture_offset($Target2/TextureRect.texture, init_data["1offset"])
	set_texture_offset($Target3/TextureRect.texture, init_data["2offset"])

	$Target1/Star.modulate = Color.WHITE if init_data["0star"] else Color(0.5, 0.5, 0.5, 1.0)
	$Target2/Star.modulate = Color.WHITE if init_data["1star"] else Color(0.5, 0.5, 0.5, 1.0)
	$Target3/Star.modulate = Color.WHITE if init_data["2star"] else Color(0.5, 0.5, 0.5, 1.0)


func set_texture_offset(texture: AtlasTexture, offset: Vector2) -> void:
	var rect := texture.region
	rect.position = offset
	texture.region = rect


func _on_button_next_pressed():
	dialog_result = 4
	close_dialog()


func _on_button_again_pressed():
	dialog_result = 2
	close_dialog()


func _on_button_exit_pressed():
	dialog_result = 3
	close_dialog()
