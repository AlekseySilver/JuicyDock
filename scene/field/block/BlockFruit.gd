extends Block
class_name BlockFruit

var fruit_id: int = 0


var check_flag: bool = false

var _can_move := true

func get_value() -> int:
	return fruit_id


func can_move() -> bool:
	return _can_move


func set_can_move(value: bool) -> void:
	_can_move = value
	$Net.visible = not value


func start_vortex_anim(time: float) -> void:
	var anim: AnimationPlayer = $AnimationPlayer
	anim.play(&"Vortex", -1.0, 1.0 / time)