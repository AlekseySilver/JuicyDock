extends Area3D
class_name Block


var block_id: Vector2i

func get_value() -> int:
	return -1

func can_move() -> bool:
	return false

func set_can_move(_value: bool) -> void:
	pass

func update_position() -> void:
	position = get_position3d()


func get_position3d() -> Vector3:
	return Vector3(block_id.x, block_id.y, 0.0)

