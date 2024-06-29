extends Area3D
class_name Button3D

signal pressed

func press() -> void:
	emit_signal("pressed")
