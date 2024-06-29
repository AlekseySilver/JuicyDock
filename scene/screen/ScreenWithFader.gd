extends Node3D
class_name ScreenWithFader

@onready var fader_anim: AnimationPlayer = $UI/Fader/AnimationPlayer
@onready var dialog_anim: AnimationPlayer = $UI/Dialog/AnimationPlayer
@onready var camera: Camera3D = $Camera3D


signal show_dialog_finished


var object2press: Object = null
var is_mouse_down: bool
var is_mouse_released_on_same_object: bool = false
var drag_start_position: Vector2
var mouse_position: Vector2
var is_paused := false

func _ready() -> void:
	await fade_out()


func fade_out():
	fader_anim.play(&"Fade", -1.0, 2.0, false)
	return fader_anim.animation_finished


func fade_in():
	fader_anim.play(&"Fade", -1.0, -2.0, true)
	return fader_anim.animation_finished


func show_dialog(dialog_resource: String, init_data = null) -> void:
	$UI/Custom.visible = false
	is_paused = true
	var dialog = load(dialog_resource).instantiate() as DialogBase
	$UI/Dialog/Container.add_child(dialog)
	dialog.prepare_show(init_data)
	dialog_anim.play(&"Show")
	await dialog_anim.animation_finished
	await dialog.closed
	dialog_anim.play_backwards(&"Show")
	await dialog_anim.animation_finished
	emit_signal(&"show_dialog_finished")
	on_dialog_result(dialog.dialog_result)
	dialog.queue_free()
	is_paused = false
	$UI/Custom.visible = true


func restart_screen() -> void:
	await fade_in()
	if get_tree(): # null when app closed
		get_tree().reload_current_scene()

func goto_screen(scene_resource_name: String) -> void:
	await fade_in()
	if get_tree(): # null when app closed
		get_tree().change_scene_to_file(scene_resource_name)


func _input(event):
	if is_paused:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_position = event.position
			is_mouse_down = event.pressed
			try_press_object()
			if is_mouse_down:
				drag_start_position = event.position
				on_drag_start()
			else:
				on_drag_finish()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			on_scroll_up()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			on_scroll_down()
		
	elif event is InputEventMouseMotion:
		mouse_position = event.position
		#print("mouse_position: ", mouse_position)
		if is_mouse_down:
			on_drag_move()


func try_press_object() -> void:
	var from := camera.project_ray_origin(mouse_position)
	var dir := camera.project_ray_normal(mouse_position)
	var to := dir * (camera.position.z * 2.0) + from
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	if result:
		if is_mouse_down:
			object2press = result.collider
			is_mouse_released_on_same_object = false
		elif result.collider == object2press:
			is_mouse_released_on_same_object = true
			object_pressed()
	else:
		cancel_object_press()

func cancel_object_press() -> void:
	object2press = null

func object_pressed() -> void:
	pass # for override

func on_drag_start() -> void:
	pass # for override

func on_drag_move() -> void:
	pass # for override

func on_drag_finish() -> void:
	pass # for override

func on_scroll_up() -> void:
	pass # for override

func on_scroll_down() -> void:
	pass # for override


func on_dialog_result(_result: int) -> void:
	pass # for override


