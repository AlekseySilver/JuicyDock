extends Control

class_name DialogBase

signal closed

var dialog_result := 0

func close_dialog() -> void:
	emit_signal("closed")


func prepare_show(_init_data) -> void:
	pass # for override


