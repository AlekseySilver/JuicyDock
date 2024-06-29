extends Block
class_name BlockCannon

@export var rotate_speed := 3.0

@onready var _face2shader: StandardMaterial3D = $Face2.get_surface_override_material(0)


var clockwise: bool
var _turn_count: int

var next_fruit_id := 0


var _dir := Vector2i.RIGHT

var _animate_rotate := false
var _source_rotation: Quaternion
var _target_rotation: Quaternion
var _animate_rotate_rate := 0.0


func _ready() -> void:
	generate_next_fruit_id()


func _process(delta) -> void:
	if _animate_rotate:
		_animate_rotate_rate += delta * rotate_speed
		if _animate_rotate_rate >= 1.0:
			_animate_rotate_rate = 1.0
			_animate_rotate = false
		basis = Basis(_source_rotation.slerp(_target_rotation, _animate_rotate_rate))



func fire() -> void:
	rotate90()
	generate_next_fruit_id()


func rotate90() -> void:
	var tc := _turn_count + (1 if clockwise else -1)
	if tc > 3:
		tc = 0
	elif tc < 0:
		tc = 3
	set_turn_count(tc)


func generate_next_fruit_id() -> void:
	next_fruit_id = clamp(randi_range(0, 8), 0, 7) # 8 for more nets

	var uv := Xts.get_fruit_uv_offset(next_fruit_id)
	_face2shader.uv1_offset = uv


func set_turn_count(value: int) -> void:
	if _turn_count != value:
		_turn_count = value
		_dir = Xts.get_direction(value)
		# start rotate anim
		_animate_rotate = true
		_source_rotation = Quaternion(basis)
		_target_rotation = Quaternion.from_euler(Vector3(0.0, 0.0, value * PI * (-0.5 if clockwise else 0.5)))
		_animate_rotate_rate = 0.0
		#print("turn ", value)
		#print("_dir ", _dir)
		#print("rot ", _target_rotation.get_euler())


func set_dir(value: Vector2i) -> void:
	if _dir != value:
		_dir = value
		set_turn_count(Xts.get_turn_count(value))



func fire_point() -> Vector2i:
	return block_id + _dir