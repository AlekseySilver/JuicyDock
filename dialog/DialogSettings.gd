extends DialogBase


func _on_button_en_pressed():
	TranslationServer.set_locale("en-US")
	close_dialog()


func _on_button_ru_pressed():
	TranslationServer.set_locale("ru-RU")
	close_dialog()

