extends Control

class_name Menu


@export var enabled = true
@export var right_side = false

@onready var _arrow = $Arrow
@onready var _arrow_animation = $ArrowAnimation
@onready var _select_sound = $SelectSound
@onready var _enter_sound = $EnterSound

var _submenu_stack: Array[Submenu]

var _active_submenu: Submenu
var _select_index = 0


func _ready():
	_arrow_animation.play("point")
	_arrow.flip_h = right_side
	call_deferred("collect_children")


func collect_children():
	for child in get_children():
		if child is Submenu:
			set_active_submenu(child)
			break


func set_active_submenu(submenu: Submenu):
	if _active_submenu != null:
		_submenu_stack.append(_active_submenu)
		_active_submenu.visible = false
		_active_submenu.disconnect("back", self.exit_submenu)

	for i in submenu.get_child_count():
		if submenu.get_child(i).visible:
			_select_index = i
			break

	_active_submenu = submenu
	submenu.reparent(self)
	submenu.visible = true
	submenu.connect("back", self.exit_submenu)
	
	submenu.current_option = submenu.get_child(_select_index).name
	
	call_deferred("update_arrow_pos")


func exit_submenu():
	var submenu_button = _active_submenu.original_parent
	_active_submenu.visible = false
	_active_submenu.disconnect("back", self.exit_submenu)
	_active_submenu.reparent(submenu_button)
	_active_submenu.exit()
	
	_active_submenu = _submenu_stack.pop_front()
	_active_submenu.visible = true
	_active_submenu.connect("back", self.exit_submenu)

	# Return arrow to the submenu's button
	_select_index = _active_submenu.get_children().find(submenu_button)
	update_arrow_pos()


func update_arrow_pos():
	var button = _active_submenu.get_child(_select_index)
	_arrow.global_position = (
		button.global_position + Vector2(
			button.size.x + 8 if right_side else -8,
			button.size.y / 2 + 1
		)
	).round()


func _progress_selection(dir):
	var origin_index = _select_index
	while true:
		_select_index += dir
		if _select_index < 0:
			_select_index = 0
		elif _select_index >= _active_submenu.get_child_count():
			_select_index = _active_submenu.get_child_count() - 1
		elif not _active_submenu.get_child(_select_index).visible:
			continue

		break

	if not _active_submenu.get_child(_select_index).visible:
		_select_index = origin_index

	if origin_index != _select_index:
		_select_sound.play()
		update_arrow_pos()
		_active_submenu.current_option = _active_submenu.get_child(_select_index).name


func _choose(index: int):
	if _active_submenu.choose():
		_enter_sound.play()

		var button = _active_submenu.get_child(index)
		if button.get_child_count() == 1:
			var child = button.get_child(0)
			if child is Submenu:  # Open up sub-menu
				set_active_submenu(child)


func _process(_delta):
	if not enabled or _active_submenu == null:
		return

	var select_dir = 0
	if Input.is_action_just_pressed("look_down"):
		select_dir += 1
	if Input.is_action_just_pressed("look_up"):
		select_dir -= 1

	if select_dir != 0:
		_progress_selection(select_dir)
	
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("enter"):
		_choose(_select_index)
		
