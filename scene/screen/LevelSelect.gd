extends ScreenWithFader

@export var camera_speed: float = 2.0
@export var scroll_speed: float = 10.0
@export var min_cam_y: float = -23.8
@export var max_cam_y: float = -0.8

const LEVEL_X_COUNT = 4
const LEVEL_Y_COUNT = 5
const OFFSET_X = -1.8
const OFFSET_Y = 1.8
const STEP_X = 1.2
const STEP_Y = -1.2
const MIN_DRAG = 5.0

@onready var levels: Node3D = $Levels


var drag_start_pos: Vector3
var drag_start_cam_pos: Vector3

var target_cam_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_cam_pos = camera.position
	target_cam_pos.y = App.levels_cam_scroll_pos
	camera.position = target_cam_pos

	super()

	var x := 0
	var y := 0
	for i in range(App.get_level_count()):
		var box := load("res://scene/misc/LevelBox.tscn").instantiate() as LevelBox
		levels.add_child(box)
		box.owner = levels.owner
		box.position = Vector3(x * STEP_X + OFFSET_X, y * STEP_Y + OFFSET_Y, 0.0)
		box.set_level_id(i)
		box.set_stars(App.get_stars(i))

		# next
		x += 1
		if x >= LEVEL_X_COUNT:
			x = 0
			y += 1



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if camera.position != target_cam_pos:
		camera.position = camera.position.lerp(target_cam_pos, delta * camera_speed)



func object_pressed() -> void:
	var button := object2press as Button3D
	if button:
		button.press()
	else:
		var box := object2press as LevelBox
		if box:
			#print("level_id: ", box.level_id)
			App.current_level_id = box.level_id
			App.levels_cam_scroll_pos = target_cam_pos.y
			goto_screen("res://scene/screen/ScreenPlay.tscn")


func get_point_on_z0() -> Vector3:
	var from := camera.project_ray_origin(mouse_position)
	var dir := camera.project_ray_normal(mouse_position)
	return dir * (camera.position.z) + from


func set_cam_target_pos(pos: Vector3) -> void:
	target_cam_pos = pos
	target_cam_pos.y = clamp(target_cam_pos.y, min_cam_y, max_cam_y)


func on_drag_start() -> void:
	drag_start_cam_pos = camera.position
	drag_start_pos = get_point_on_z0()
	#print("drag_start_pos: ", drag_start_pos)


func on_drag_move() -> void:
	var pos := get_point_on_z0()
	if (pos - drag_start_pos).length_squared() > MIN_DRAG:
		cancel_object_press()

	#print("mouse_position: ", mouse_position)
	#print("pos: ", pos)

	set_cam_target_pos(drag_start_cam_pos + Vector3(0.0, drag_start_pos.y - pos.y, 0.0))


func on_scroll_up() -> void:
	set_cam_target_pos(camera.position + Vector3(0.0, scroll_speed, 0.0))

func on_scroll_down() -> void:
	set_cam_target_pos(camera.position + Vector3(0.0, -scroll_speed, 0.0))


func _on_button_random_pressed():
	App.current_level_id = -1
	goto_screen("res://scene/screen/ScreenPlay.tscn")


func _on_button_settings_pressed():
	show_dialog("res://dialog/DialogSettings.tscn")



func on_dialog_result(_result: int) -> void:
	App.save()

