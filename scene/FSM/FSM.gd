extends Node

@export var active_action: FSMAction
@export var default_action: FSMAction

func update() -> void:
	if active_action:
		active_action.update(get_parent())
	elif default_action:
		_set_as_active(default_action)


func _set_as_active(action: FSMAction) -> void:
	active_action = action;
	if active_action == null:
		active_action = default_action
	if active_action:
		active_action.start()


func set_as_active(action_name: StringName) -> void:
	var action = get_node_or_null(NodePath(action_name)) as FSMAction
	if action:
		_set_as_active(action)

