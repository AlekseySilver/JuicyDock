extends MeshInstance3D


@export var materials: Array[String]

@export var speed := 0.1

@export var min_dst: Vector2
@export var max_dst: Vector2


var _dst: Vector2 # destination
var _dir: Vector2 # direction from _src to _dst


func _ready() -> void:
	position = Xts.XYA(get_rnd_point(), position.z)
	set_new_destination()

	#await get_tree().create_timer(1.0).timeout

	var res: String = materials[randi_range(0, len(materials) - 1)]
	material_override = load(res)



func _process(delta: float) -> void:
	var check := _dst.x > position.x
	position += Xts.XY0(_dir * (speed * delta))
	if check != (_dst.x > position.x): # destination reached
		set_new_destination()


func set_new_destination() -> void:
	_dst = get_rnd_point()
	_dir = (_dst - Xts.XY(position)).normalized()


func get_rnd_point() -> Vector2:
	return Vector2(randf_range(min_dst.x, max_dst.x), randf_range(min_dst.y, max_dst.y))

