class_name Xts

static func get_bytes_from_int(i: int) -> Array[int]:
	var arr := [0, 0, 0, 0] as Array[int]
	arr[0] = (i >> 0) & 0xFF
	arr[1] = (i >> 8) & 0xFF
	arr[2] = (i >> 16) & 0xFF
	arr[3] = (i >> 24) & 0xFF
	return arr

static func get_int_from_byte_array(arr: Array[int]) -> int:
	var i: int = 0
	i &= ((arr[0] & 0xFF) << 0)
	i &= ((arr[1] & 0xFF) << 8)
	i &= ((arr[2] & 0xFF) << 16)
	i &= ((arr[3] & 0xFF) << 24)
	return i

static func get_bit_from_int(i: int, bit_id: int) -> bool:
	return (i >> bit_id) & 0x01 > 0

static func set_bit_to_int(i: int, bit_id: int, value: bool) -> int:
	if value:
		return (1 << bit_id) | i
	return ~(i << bit_id) & i


# clockwise
static func get_direction(turn_count: int) -> Vector2i:
	match turn_count:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.UP
		2:
			return Vector2i.LEFT
		3:
			return Vector2i.DOWN
	return Vector2i.ZERO


# clockwise
static func get_turn_count(dir: Vector2i) -> int:
	if dir.x == 1:
		return 0
	if dir.y == -1:
		return 1
	if dir.x == -1:
		return 2
	return 3


static func get_turn_invert(turn: int) -> int:
	return (turn + 2) % 4


# rotate vector on 90 degrees
static func rotate90(dir: Vector2i, clockwise: bool) -> Vector2i:
	if clockwise:
		return Vector2i(dir.y, -dir.x)
	return Vector2(-dir.y, dir.x)


static func XY0(v2: Vector2) -> Vector3:
	return Vector3(v2.x, v2.y, 0.0)

static func XYA(v2: Vector2, a: float) -> Vector3:
	return Vector3(v2.x, v2.y, a)

static func XY(v3: Vector3) -> Vector2:
	return Vector2(v3.x, v3.y)


static func get_fruit_uv_offset(fruit_id: int) -> Vector3:
	return Vector3(0.125 * (fruit_id + 1), 0.0, 0.0) if fruit_id < 7 else Vector3(0.125, 0.125, 0.0)