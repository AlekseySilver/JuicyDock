extends Area3D
class_name LevelBox

@onready var level_number: Label3D = $LevelNumber


var level_id: int = 0


func set_level_id(value: int) -> void:
	level_id = value
	level_number.text = str(level_id + 1)


func set_stars(value: int) -> void:
	$Star1.get_surface_override_material(0).albedo_color = Color.WHITE if Xts.get_bit_from_int(value, 0) else Color(0.5, 0.5, 0.5, 1.0)
	$Star2.get_surface_override_material(0).albedo_color = Color.WHITE if Xts.get_bit_from_int(value, 1) else Color(0.5, 0.5, 0.5, 1.0)
	$Star3.get_surface_override_material(0).albedo_color = Color.WHITE if Xts.get_bit_from_int(value, 2) else Color(0.5, 0.5, 0.5, 1.0)

