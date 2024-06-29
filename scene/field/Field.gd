extends Node3D
class_name Field

@export_file var boom_file_path: String

@onready var _fsm := $FSM
@onready var _boom_resource: Resource = load(boom_file_path)
@onready var _net_fly: MeshInstance3D = $NetFly

const FIELD_SIZE = 8
const FIELD_SIZE_M1 = FIELD_SIZE - 1
const FRUIT_COUNT = 7
const MAX_BLOCK_COUNT = FIELD_SIZE * FIELD_SIZE
const VORTEX_ANIMATION_TIME = 0.75
const BOOM_ANIMATION_TIME = 0.5
const PER_CELL_ANIMATION_TIME = 0.05
const BLOCK_SHIFT_SPEED = 1.0


signal combo_changed(value: int)
signal rest_changed(value: String)
signal game_finished


enum EPlayMode {FRUIT0, FRUIT1, FRUIT2, FRUIT3, FRUIT4, FRUIT5, FRUIT6, STEP, TIME, COMBO}

var _play_mode := [EPlayMode.FRUIT0, EPlayMode.FRUIT0, EPlayMode.FRUIT0]
var _mode_value := [0, 0, 0]
var _blocks := [] # 2D array of Block
var _block_total := 0
var _fruit_total := 0
var _fruit_list := [] # array of Array[BlockFruit]
var _cannon := [] as Array[BlockCannon]
var _vortex := [] as Array[BlockVortex]
var _current_vortex: BlockVortex = null
var _got_fruit := [0, 0, 0, 0, 0, 0, 0]
var _rest := 0
var _finish_reason := -1
var _animation_time_left := 0.0
var _animation_time_total := 0.0
var _delta_time := 0.1
var _find_remove := false
var _boom_list := [] as Array[Block]
var _check_flag := false
var _user_made_move := false
var _combo := 0
var _max_combo := 0
var _vortex_block: BlockFruit = null
var _time := 0.0
var _rest_time_delta := 0.0
var _step := 0
var _cannon_id := 0 # current cannon
var _dir2shift: Vector2i
var _count2shift := 0
var _last2shift: Vector2i
var _shift: Vector2i
var _speed: Vector2
var _cannon_net_target: Block

var _selected_block_id := Vector2i.LEFT # LEFT -> not selected



func _ready() -> void:
	# init _blocks arr
	for i in range(FIELD_SIZE):
		var arr := [] as Array[Block]
		arr.resize(FIELD_SIZE)
		_blocks.push_back(arr)

	# init fruit_arr
	for i in range(FRUIT_COUNT):
		var fruit_arr := [] as Array[BlockFruit]
		_fruit_list.push_back(fruit_arr)


func update(delta: float) -> void:
	_delta_time = delta
	_fsm.update()


func load() -> void:
	if App.current_level_id < 0:
		load_random()
	else:
		load_custom()

	set_rest(_mode_value[0]) # first star determines whether the level has been completed and limits the player to the level


func load_custom() -> void:
	var lv = App.get_current_level()
	var k

	# blocks adding
	for i in lv["b"]:
		var b := Xts.get_bytes_from_int(i)
		match b[2]:
			7: # static block
				k = load("res://scene/field/block/BlockStatic.tscn").instantiate()
			8: # dummy moveable
				k = load("res://scene/field/block/BlockDummy.tscn").instantiate()
			14: # vortex
				k = load("res://scene/field/block/BlockVortex.tscn").instantiate()
			13: # cannon
				k = load("res://scene/field/block/BlockCannon.tscn").instantiate()
				var bb := b[3]
				k.clockwise = Xts.get_bit_from_int(bb, 0)
				var tc := 0
				if Xts.get_bit_from_int(bb, 1):
					tc += 1
				if Xts.get_bit_from_int(bb, 2):
					tc += 2
				k.set_turn_count(tc)
			_: # fruit
				var fruit_id := b[2]
				k = load("res://scene/field/block/BlockFruit" + str(fruit_id) + ".tscn").instantiate()
				k.fruit_id = fruit_id
				k.set_can_move(b[3] == 0)
		add_block(Vector2i(b[0], FIELD_SIZE_M1 - b[1]), k)
	
	# play mode
	for i in range(len(_play_mode)):
		var b := Xts.get_bytes_from_int(lv["r"][i])
		_play_mode[i] = b[0]
		_mode_value[i] = b[1]


func rnd_coord() -> int:
	return clamp(randi_range(0, FIELD_SIZE), 0, FIELD_SIZE_M1)

func rnd_point() -> Vector2i:
	return Vector2i(rnd_coord(), rnd_coord())


func load_random():
	# the principle of random filling:
	# a random fruit is selected
	# a random maximum number of fruits of the same type is selected
	# coordinates are selected for each
	# the first fruit in the web
	# if one of the following fruits is in the web
	# then the next one in the web can only be through the number of fruits at least the distance to the nearest one in the web

	const TIME_PER_BLOCK = 5 # time per block
	const DUMMY_BLOCKS_MIN = 3
	const DUMMY_BLOCKS_MAX = 5
	const MAX_FRUIT_ITER = 10 # number of fruit type selection
	const MAX_POS_ITER = 100 # number of coordinates selection

	const MIN_CANT_MOVE_PERCENT = 1
	const MAX_CANT_MOVE_PERCENT = 99
	const MIN_FRUIT_COUNT = 5 # min number of fruits of the same type
	const MAX_FRUIT_COUNT = 15 # max number of fruits of the same type


	const PAR_COUNT = 2
	const STEP_COUNT = 10

	
	var all_add := App.random_difficulty / PAR_COUNT
	var last_add := App.random_difficulty % PAR_COUNT

	var cant_move_percent := int(float(MAX_CANT_MOVE_PERCENT - MIN_CANT_MOVE_PERCENT) / STEP_COUNT * all_add) + MIN_CANT_MOVE_PERCENT # % can't move
	var fruit_type_count := int(float(MAX_FRUIT_COUNT - MIN_FRUIT_COUNT) / STEP_COUNT * (all_add + (1 if last_add > 0 else 0))) + MIN_FRUIT_COUNT
	
	# adding dummies
	var cc := randi_range(DUMMY_BLOCKS_MIN, DUMMY_BLOCKS_MAX)
	while cc > 0:
		cc -= 1
		var c := MAX_POS_ITER
		while c > 0: # the cycle for selecting the coordinates of the fruit
			c -= 1
			if add_block(rnd_point(), load("res://scene/field/block/BlockDummy.tscn").instantiate()):
				break

	# adding fruits
	cc = MAX_FRUIT_ITER
	while cc > 0: # cycle by type of fruit
		cc -= 1
		var fruit_id := randi_range(0, FRUIT_COUNT - 1)
		if len(_fruit_list[fruit_id]) > 0:
			continue # such fruits are already filled

		var max_c := randi_range(2, fruit_type_count - 1)
		var cant_move_count := 0 # number of stationary fruits
		var need_free := 0

		while max_c > 0: # cycle by number of fruits
			max_c -= 1
			var c := MAX_POS_ITER
			while c > 0: # the cycle for selecting the coordinates of the fruit
				c -= 1
				var p := rnd_point()
				if get_block(p):
					continue
				
				var b := load("res://scene/field/block/BlockFruit" + str(fruit_id) + ".tscn").instantiate() as BlockFruit
				b.fruit_id = fruit_id
				var nf := 0
				if randi_range(0, 99) < cant_move_percent:
					if cant_move_count > 0:
						nf = get_need_free(fruit_id, p)
						if need_free + nf < max_c:
							b.set_can_move(false)
					else:
						b.set_can_move(false)

				if b.can_move:
					need_free -= 1
				else:
					cant_move_count += 1
					need_free += nf

				add_block(p, b)
				break


	for i in range(2):
		_play_mode[i] = EPlayMode.TIME
		_mode_value[i] = int(_block_total * TIME_PER_BLOCK / float(i + 1))

	_play_mode[2] = EPlayMode.COMBO
	_mode_value[2] = 0
	for fe in _fruit_list:
		if len(fe) > 0:
			_mode_value[2] += 1
	_mode_value[2] -= 1


# returns the number of fruits to connect the current one with the nearest one in the grid
func get_need_free(fruit_id: int, point: Vector2i) -> int:
	var res := FIELD_SIZE * 2
	for f in _fruit_list[fruit_id]:
		if f.can_move():
			continue
		var d: int = abs(f.block_id.x - point.x) + abs(f.block_id.y - point.y)
		if d < res:
			res = d
	return res



# add block to field
func add_block(pos: Vector2i, block: Block, replace: bool = false) -> bool:
	if _blocks[pos.x][pos.y]:
		if replace:
			remove_block(pos)
		else:
			return false
	_blocks[pos.x][pos.y] = block
	block.block_id = pos
	var _t = is_fruit_check(block, 1) or is_cannon_check(block, true) or is_vortex_check(block, true)
	_block_total += 1

	add_child(block)
	block.owner = owner
	block.update_position()

	return true


func remove_block(pos: Vector2i) -> bool:
	var block := _blocks[pos.x][pos.y] as Block
	if block == null:
		return false

	var _t = is_fruit_check(block, -1) or is_cannon_check(block, false) or is_vortex_check(block, false)
	_block_total -= 1
	_blocks[pos.x][pos.y] = null
	remove_child(block)
	block.queue_free()
	return true


func is_fruit_check(block: Block, step: int) -> bool:
	var b = block as BlockFruit
	if b == null:
		return false
	if step > 0:
		_fruit_list[b.get_value()].push_back(b)
	else:
		_fruit_list[b.get_value()].erase(b)
		dec_rest_fruit(b.get_value())
	_fruit_total += step
	return true

func is_cannon_check(block: Block, add: bool) -> bool:
	var b = block as BlockCannon
	if b == null:
		return false
	if add:
		_cannon.push_back(b)
	else:
		_cannon.erase(b)
	return true

func is_vortex_check(block: Block, add: bool) -> bool:
	var b = block as BlockVortex
	if b == null:
		return false
	if add:
		_vortex.push_back(b)
	else:
		_vortex.erase(b)
	return true



func get_play_mode_fruit_id() -> int:
	return _play_mode[0]

func check_fruit_play_mode(fruit_id: int) -> bool:
	var play_mode_fruit_id := get_play_mode_fruit_id()
	return play_mode_fruit_id == fruit_id and play_mode_fruit_id >= 0 and play_mode_fruit_id < FRUIT_COUNT


func get_play_mode_texture_offset() -> Vector3:
	var v: Vector3
	match _play_mode[0]:
		EPlayMode.STEP:
			v = Vector3(0.875, 0.875, 0.0)
		EPlayMode.TIME:
			v = Vector3(0.75, 0.875, 0.0)
		EPlayMode.COMBO:
			v = Vector3(0.875, 0.75, 0.0)
		_:
			v = Xts.get_fruit_uv_offset(_play_mode[0])
	return v


func set_rest(value: int) -> void:
	if _rest == value:
		return
	_rest = value
	if _rest < 0:
		_rest = 0
		match _play_mode[0]:
			EPlayMode.STEP:
				_finish_reason = 1 # lose: steps out
				_fsm.set_as_active(&"CheckWinLose")
			EPlayMode.TIME:
				_finish_reason = 2 # lose: time out
				_fsm.set_as_active(&"CheckWinLose")

	var text: String
	match _play_mode[0]:
		EPlayMode.STEP:
			text = "STEP_REST"
		EPlayMode.TIME:
			text = "TIME_REST"
		EPlayMode.COMBO:
			text = "COMBO_NEED"
		_:
			text = "FRUIT_NEED"
	text = str(_rest) + tr(text)
	emit_signal("rest_changed", text)


func set_combo(value: int) -> void:
	if _combo != value:
		_combo = value
		if _combo > _max_combo:
			_max_combo = _combo
		# show combo
		emit_signal("combo_changed", _combo)

func is_in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 && p.y >= 0 && p.x < FIELD_SIZE && p.y < FIELD_SIZE


func get_block(p: Vector2i) -> Block:
	if is_in_bounds(p):
		return _blocks[p.x][p.y]
	return null


func find_next_vortex_block() -> bool:
	for i in len(_vortex):
		for j in range(4):
			_current_vortex = _vortex[i]
			var xy = _current_vortex.block_id + Xts.get_direction(j)
			var b = get_block(xy) as BlockFruit
			if b and b.can_move:
				_vortex_block = b
				return true
	return false




func dec_rest_time() -> void:
	if _finish_reason >= 0:
		return
	_time += _delta_time
	if _play_mode[0] == EPlayMode.TIME:
		_rest_time_delta += _delta_time
		if _rest_time_delta >= 1.0:
			_rest_time_delta = 0.0
			set_rest(_rest - 1)


func dec_rest_step() -> void:
	_step += 1
	if _play_mode[0] == EPlayMode.STEP:
		set_rest(_rest - 1)


func dec_rest_fruit(fruit_id: int) -> void:
	_got_fruit[fruit_id] += 1 # got one more fruit
	if check_fruit_play_mode(fruit_id):
		set_rest(_rest - 1)


func start_animation(total_time: float) -> void:
	_animation_time_left = total_time
	_animation_time_total = total_time

func get_animation_rate() -> float:
	return _animation_time_left / _animation_time_total

func decrease_animation_time() -> void:
	_animation_time_left -= _delta_time

func get_is_animation_end() -> bool:
	return _animation_time_left <= 0.0


func find_remove_queue() -> bool:
	swap_check_flag()

	var max_count := 0
	var one_list := [] as Array[BlockFruit]

	for d in _fruit_list:
		var ln := len(d)
		if ln == 0:
			continue
		
		if ln > max_count:
			max_count = ln
		
		if ln == 1:
			one_list = d
			continue

		for b in d:
			if b.check_flag == _check_flag:
				continue #already checked

			# seek for same fruits
			var c = same_count(b.block_id, b.get_value())
			if (c >= len(_fruit_list[b.get_value()])): # count, enough to remove
				return true;

			b.check_flag = _check_flag;
			_boom_list.clear()

	if max_count < 2 and one_list: # add to boom single fruit block
		_boom_list.push_back(one_list[0])
		return true
	return false


func swap_check_flag() -> void:
	# all cells marked as nonchecked
	for d in _fruit_list:
		for b in d:
			b.check_flag = _check_flag
	# swap global check flag
	_check_flag = not _check_flag


func same_count(xy: Vector2i, value: int) -> int:
	var count := 0
	var dir := Vector2i.RIGHT
	while true: # cycle in 4 directions
		var d := xy + dir
		var b2 = get_block(d) as BlockFruit
		if b2 and b2.check_flag != _check_flag and b2.get_value() == value:
			_boom_list.push_back(b2)
			b2.check_flag = _check_flag
			count += 1
			count += same_count(d, value)

		if dir.y == 1: # final dir
			break
		dir = Xts.rotate90(dir, true)

	return count


# remove nets near boom
func surround_net_boom(p: Vector2i) -> void:
	var jb: int = max(p.y - 1, 0)
	var je: int = min(p.y + 2, FIELD_SIZE)
	var ib: int = max(p.x - 1, 0)
	var ie: int = min(p.x + 2, FIELD_SIZE)

	for j in range(jb, je, 1):
		for i in range(ib, ie, 1):
			var b := get_block(Vector2i(i, j))
			if b == null:
				continue
			if not b.can_move():
				b.set_can_move(true)


func check_win() -> bool:
	match _play_mode[0]:
		EPlayMode.STEP:
			return check_win_step_time()
		EPlayMode.TIME:
			return check_win_step_time()
		EPlayMode.COMBO:
			return check_win_combo()
	return check_win_fruit()


func check_win_step_time() -> bool:
	return _fruit_total <= 0

func check_win_combo() -> bool:
	return _max_combo >= _mode_value[0]

func check_win_fruit() -> bool:
	return _got_fruit[get_play_mode_fruit_id()] >= _mode_value[0]


func check_can_move() -> bool:
	if _block_total == MAX_BLOCK_COUNT:
		return false # all field blocked

	# check have block to move
	var fruit := false
	var dummy := false
	
	for j in range(FIELD_SIZE):
		for i in range(FIELD_SIZE):
			var b = _blocks[i][j]
			if b and b.can_move:
				dummy = dummy or b is BlockDummy
				fruit = fruit or b is BlockFruit
				if dummy and fruit:
					break
		if dummy and fruit:
			break

	if len(_cannon) == 0 and not fruit:
		return false
	return fruit or dummy


func is_cannon_cycle() -> bool:
	return _cannon_id < len(_cannon)


func can_move(xy: Vector2) -> bool:
	var b := get_block(xy)
	return b.can_move() if b else false


func try_move_cells(xy: Vector2i) -> bool:
	if not can_move(xy):
		return false

	assert(_dir2shift != Vector2i.ZERO)

	# shift direction
	if abs(_dir2shift.x) > abs(_dir2shift.y):
		_dir2shift.x = sign(_dir2shift.x)
		_dir2shift.y = 0
	else:
		_dir2shift.x = 0
		_dir2shift.y = sign(_dir2shift.y)

	# look for outermost filled cell in the shift direction
	_count2shift = 0
	_last2shift = xy
	while true:
		_last2shift += _dir2shift
		_count2shift += 1
		if can_move(_last2shift) and get_block(_last2shift):
			continue

		_last2shift -= _dir2shift
		break
	
	# delta - how much we can shift
	_shift = _last2shift
	while true:
		_shift += _dir2shift
		if is_in_bounds(_shift) and get_block(_shift) == null:
			continue

		_shift -= _dir2shift
		_shift -= _last2shift
		break

	if _shift.x == 0 and _shift.y == 0:
		return false

	return true


# goto next cannon
func cannon_next() -> void:
	var c := _cannon[_cannon_id]
	c.fire()
	_cannon_id += 1

	if is_cannon_cycle():
		cannon_fire()
	else:
		_fsm.set_as_active(&"Vortex")


func cannon_fire() -> void:
	var c := _cannon[_cannon_id]
	if c.next_fruit_id < FRUIT_COUNT:
		cannon_place_block()
	else: # net
		_fsm.set_as_active(&"CannonNetAnimate")


#try place block
func cannon_place_block() -> void:
	if cannon_try_place_block():
		_fsm.set_as_active(&"ListenUserInput")
		on_drag_finish(_dir2shift)
	else:
		cannon_next()

func cannon_try_place_block() -> bool:
	var c = _cannon[_cannon_id]
	var fire_point = c.fire_point()
	if not is_in_bounds(fire_point):
		return false

	var near_block := get_block(fire_point)
	if near_block:
		return false # can't fire

	var b = load("res://scene/field/block/BlockFruit" + str(c.next_fruit_id) + ".tscn").instantiate()
	b.fruit_id = c.next_fruit_id
	add_block(fire_point, b)

	_dir2shift = c._dir
	_selected_block_id = fire_point # point of installation of a new block from the cannon

	return true


func move_cell(xy: Vector2i, shift: Vector2i) -> bool:
	var new_pos := xy + shift
	if get_block(new_pos):
		return false
	var b := get_block(xy)
	_blocks[new_pos.x][new_pos.y] = b
	_blocks[xy.x][xy.y] = null

	b.block_id = new_pos
	b.update_position()
	return true


func cannon_start() -> void:
	_cannon_id = 0
	if is_cannon_cycle():
		cannon_fire()
	else:
		_fsm.set_as_active(&"Vortex")


func get_win_dialog_init_data() -> Dictionary:
	var init_data = {}

	for i in range(len(_play_mode)):
		var strmode: String
		var offset: Vector2
		var star: bool
		match _play_mode[i]:
			EPlayMode.TIME:
				strmode = "MAX_TIME"
				offset = Vector2(384, 448)
				star = _time <= _mode_value[i]
			EPlayMode.STEP:
				strmode = "MAX_STEP"
				offset = Vector2(448, 448)
				star = _step <= _mode_value[i]
			EPlayMode.COMBO:
				strmode = "MIN_COMBO"
				offset = Vector2(448, 384)
				star = _max_combo >= _mode_value[i]
			_:
				strmode = "MIN_FRUIT"
				offset = Xts.XY(Xts.get_fruit_uv_offset(_play_mode[i])) * 512.0
				star = _got_fruit[_play_mode[i]] >= _mode_value[i]

		init_data[str(i) + "text"] = tr(strmode) + str(_mode_value[i])
		init_data[str(i) + "offset"] = offset
		init_data[str(i) + "star"] = star

	return init_data




########### FSM #####################
# Vortex - check blocks to remove ----------------------------------------------------
func vortex_on_start() -> void:
	if find_next_vortex_block():
		_vortex_block.start_vortex_anim(VORTEX_ANIMATION_TIME)
		start_animation(VORTEX_ANIMATION_TIME)

func vortex_check_finish() -> bool:
	decrease_animation_time()
	if get_is_animation_end():
		if _vortex_block:
			remove_block(_vortex_block.block_id)
			_vortex_block = null
			_fsm.active_action.start() # check again
		else:
			_fsm.set_as_active(&"CheckRemove")
			return true
	else:
		_vortex_block.position = _current_vortex.position.lerp(_vortex_block.position, get_animation_rate())
	return false

# CheckRemove - check for boom ----------------------------------------------------
func check_remove_on_start() -> void:
	_find_remove = find_remove_queue()
	if _find_remove:
		for i in _boom_list:
			var p = i.block_id
			remove_block(p)
			surround_net_boom(p)

			var boom = _boom_resource.instantiate()
			add_child(boom)
			boom.owner = owner
			boom.position = i.get_position3d()
			#print(i.get_position3d())
		
		#boom anim start
		start_animation(BOOM_ANIMATION_TIME)


func check_remove_check_finish() -> bool:
	decrease_animation_time()
	if get_is_animation_end():
		if _find_remove:
			set_combo(_combo + 1)
			_boom_list.clear()
			_fsm.active_action.start() # check again
		else:
			if _user_made_move:
				set_combo(0) # reset combo counter
			_fsm.set_as_active(&"CheckWinLose")
		if _user_made_move:
			_user_made_move = false

	return false


# CheckWinLose ----------------------------------------------------
func check_win_lose_on_start() -> void:
	if _finish_reason < 0:
		if check_win():
			_finish_reason = 0
		else:
			if check_can_move(): # lose if no way to move
				return # not finished
			_finish_reason = 1
	# finished
	start_animation(BOOM_ANIMATION_TIME)

func check_win_lose_check_finish() -> bool:
	decrease_animation_time()
	if get_is_animation_end():
		if _finish_reason < 0:
			_fsm.set_as_active(&"ListenUserInput")
		else:
			emit_signal("game_finished")
		return true
	return false


# ListenUserInput ----------------------------------------------------
func listen_user_input_check_finish() -> bool:
	dec_rest_time()
	return false

func on_drag_start(object2press: Object) -> void:
	if _fsm.active_action.name == &"ListenUserInput":
		var block = object2press as Block
		_selected_block_id = block.block_id if block else Vector2i.LEFT

func on_drag_finish(dir2shift: Vector2) -> void:
	if _fsm.active_action.name == &"ListenUserInput":
		if _selected_block_id.x >= 0:
			_dir2shift = dir2shift
			if try_move_cells(_selected_block_id):
				_user_made_move = true
				start_animation(PER_CELL_ANIMATION_TIME * (abs(_shift.x) + abs(_shift.y)))
				_fsm.set_as_active(&"AnimateMove")
			elif is_cannon_cycle():
				cannon_next()
			else:
				_fsm.set_as_active(&"ListenUserInput")

			_selected_block_id = Vector2i.LEFT


# AnimateMove ----------------------------------------------------
func animate_move_on_start() -> void:
	_speed = _dir2shift
	_speed *= BLOCK_SHIFT_SPEED / PER_CELL_ANIMATION_TIME

func animate_move_check_finish() -> bool:
	decrease_animation_time()

	# shift visually (move in the opposite direction)
	var last := _last2shift
	for i in range(_count2shift):
		get_block(last).position += Xts.XY0(_speed * _delta_time)
		last -= _dir2shift
	
	if get_is_animation_end():
		# shift physical (move in the opposite direction)
		last = _last2shift
		for i in range(_count2shift):
			move_cell(last, _shift)
			last -= _dir2shift
		
		if is_cannon_cycle():
			cannon_next()
		else:
			cannon_start()
			dec_rest_step()
	return false


# CannonNetAnimate ----------------------------------------------------
func cannon_net_anim_on_start() -> void:
	var c := _cannon[_cannon_id]
	var point = c.fire_point();
	if not is_in_bounds(point):
		return

	_cannon_net_target = null
	while true:
		_cannon_net_target = get_block(point)
		if _cannon_net_target:
			break
		point += c._dir
		if not is_in_bounds(point):
			break

	if _cannon_net_target:
		_net_fly.position = Xts.XYA(Xts.XY(c.position), _net_fly.position.z)
		_net_fly.visible = true
		start_animation(PER_CELL_ANIMATION_TIME * (abs(_shift.x) + abs(_shift.y)))
	else:
		_animation_time_left = 0.0

func cannon_net_anim_check_finish() -> bool:
	decrease_animation_time()
	if get_is_animation_end():
		if _cannon_net_target:
			_cannon_net_target.set_can_move(false)
			_cannon_net_target = null
			
		_net_fly.visible = false
		cannon_next()
	else:
		if _cannon_net_target:
			var c := _cannon[_cannon_id]
			var from := Xts.XYA(Xts.XY(c.position), _net_fly.position.z)
			var to := Xts.XYA(Xts.XY(_cannon_net_target.position), _net_fly.position.z)
			_net_fly.position = to.lerp(from, get_animation_rate())

	return false


