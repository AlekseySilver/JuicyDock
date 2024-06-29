extends ScreenWithFader


@onready var _field: Field = $Field
@onready var _combo_mesh := $MeshCombo
@onready var _combo_label := $MeshCombo/LabelCombo
@onready var _rest_mesh := $MeshRest
@onready var _rest_label := $MeshRest/LabelRest


func _ready() -> void:
	super()
	_field.load()
	_rest_mesh.get_surface_override_material(0).uv1_offset = _field.get_play_mode_texture_offset()
	$LabelNumber.text = str(App.current_level_id + 1) if App.current_level_id >= 0 else tr("RANDOM")


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if is_paused:
		return

	_field.update(delta)


func object_pressed() -> void:
	var button := object2press as Button3D
	if button:
		button.press()


func on_drag_start() -> void:
	_field.on_drag_start(object2press)

func on_drag_finish() -> void:
	if not is_mouse_released_on_same_object:
		var direction := mouse_position - drag_start_position
		direction.y = -direction.y
		_field.on_drag_finish(direction)
	

func _on_button_back_pressed() -> void:
	show_dialog("res://dialog/DialogPause.tscn")


func _on_button_info_pressed():
	show_dialog("res://dialog/DialogInfo.tscn", _field.get_win_dialog_init_data())


func on_dialog_result(result: int) -> void:
	match result:
		2:
			restart_screen()
		3:
			goto_screen("res://scene/screen/LevelSelect.tscn")
		4:
			if App.select_next_level_id():
				goto_screen("res://scene/screen/ScreenPlay.tscn")
			else:
				goto_screen("res://scene/screen/LevelSelect.tscn")


func _on_field_combo_changed(value: int):
	if value > 0:
		_combo_mesh.visible = true
		_combo_label.text = str(value) + tr(&"COMBOX")
	else:
		_combo_mesh.visible = false


func _on_field_rest_changed(value: String):
	_rest_label.text = value


func _on_field_game_finished():
	if _field._finish_reason == 0:
		App.random_difficulty_add(1) # adaptive random difficulty

		var init_data := _field.get_win_dialog_init_data()
		App.save_stars(App.current_level_id, init_data["0star"], init_data["1star"], init_data["2star"])
		show_dialog("res://dialog/DialogWin.tscn", init_data)
	else:
		App.random_difficulty_add(-3) # adaptive random difficulty

		show_dialog("res://dialog/DialogLose.tscn", "TIME_IS_UP" if _field._finish_reason == 2 else "NO_MOVES_LEFT")

