extends Node


const CONFIG_FILE_NAME = "user://scores.cfg"


var current_level_id: int

var levels_json: Dictionary
var levels_cam_scroll_pos: float = -0.8

var config: ConfigFile

var random_difficulty: int # difficulty for random levels


func _ready() -> void:
	var file = FileAccess.open("res://data/level.json", FileAccess.READ)
	levels_json = JSON.parse_string(file.get_as_text())
	file.close()

	config = ConfigFile.new()
	config.load(CONFIG_FILE_NAME)
	current_level_id = config.get_value("main", "current_level_id", 0)
	random_difficulty = config.get_value("main", "random_difficulty", 0)

	var locale = config.get_value("main", "locale")
	if locale:
		TranslationServer.set_locale(locale)


func save() -> void:
	config.set_value("main", "current_level_id", current_level_id)
	config.set_value("main", "random_difficulty", random_difficulty)
	config.set_value("main", "locale", TranslationServer.get_locale())
	config.save(CONFIG_FILE_NAME)


func get_stars(level_id: int) -> int:
	var data: int = config.get_value("level", str(level_id), 0)
	return data

func save_stars(level_id: int, star1: bool, star2: bool, star3: bool) -> void:
	var data := get_stars(level_id)
	var add := Xts.set_bit_to_int(0, 0, star1)
	add = Xts.set_bit_to_int(add, 1, star2)
	add = Xts.set_bit_to_int(add, 2, star3)
	data = data | add
	config.set_value("level", str(level_id), data)
	save()


func get_current_level() -> Dictionary:
	return levels_json["level"][current_level_id]


func get_level_count() -> int:
	return len(levels_json["level"])


func select_next_level_id() -> bool:
	if current_level_id < 0:
		return true
	var next := current_level_id + 1
	if next < get_level_count():
		current_level_id = next
		return true
	return false


func random_difficulty_add(value: int):
	if current_level_id < 0:
		random_difficulty = clamp(random_difficulty + value, 0, 20)