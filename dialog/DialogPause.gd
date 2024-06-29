extends DialogBase


func _on_button_play_pressed():
	dialog_result = 1
	close_dialog()


func _on_button_again_pressed():
	dialog_result = 2
	close_dialog()


func _on_button_exit_pressed():
	dialog_result = 3
	close_dialog()
