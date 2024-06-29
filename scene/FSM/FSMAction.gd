extends Node
class_name FSMAction

@export var on_start_method: StringName
@export var check_finish_method: StringName

enum EActionState {FINISHED, ACTIVE, START}

var _state := EActionState.FINISHED

func start():
	#print(name, "START")
	_state = EActionState.START

func update(fsm_parent: Node) -> void:
	if _state == EActionState.FINISHED:
		return
		
	# check need start
	if _state == EActionState.START:
		_state = EActionState.ACTIVE
		if fsm_parent.has_method(on_start_method):
			fsm_parent.call(on_start_method)
		
	# check is finished
	if fsm_parent.has_method(check_finish_method):
		if fsm_parent.call(check_finish_method):
			_state = EActionState.FINISHED

