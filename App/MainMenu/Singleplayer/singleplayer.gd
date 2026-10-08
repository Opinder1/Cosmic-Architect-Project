extends Control

@onready var game_list: Control = find_child("GameList")
@export var button_group := ButtonGroup.new()
var saves_directory: String = ProjectSettings.get("cosmic/universe/path")
var directory: DirAccess
var error_dialog: AcceptDialog

signal selected_save(save_directory: String)

func _ready() -> void:
	error_dialog = AcceptDialog.new()
	add_child(error_dialog)
	visibility_changed.connect(_on_visibility_change)
	$GameCommands/Play.pressed.connect(_on_press_play)
	$GameCommands/CreateNew.pressed.connect(_on_press_createnew)
	# These commands have no implementation yet.
	$GameCommands/Delete.disabled = true
	$GameCommands/Rename.disabled = true
	refresh()

func _on_visibility_change() -> void:
	if is_node_ready() and is_visible_in_tree():
		refresh()

func refresh(selected: String = "") -> void:
	var error := DirAccess.make_dir_recursive_absolute(saves_directory)
	if error != OK:
		_show_error("Could not create save directory: " + error_string(error))
		return
	directory = DirAccess.open(saves_directory)
	if directory == null:
		_show_error("Could not open save directory: " + error_string(DirAccess.get_open_error()))
		return
	# Rebuild from disk so external save changes and newly-created saves appear together.
	for child in game_list.get_children():
		game_list.remove_child(child)
		child.queue_free()
	var saves := directory.get_directories()
	saves.sort()
	for save in saves:
		var game := GalaxyEntry.new()
		game.text = save
		game.galaxy_dir = save
		game.button_group = button_group
		game.toggle_mode = true
		game.toggled.connect(func(_pressed: bool): _update_commands())
		game_list.add_child(game)
		if save == selected:
			game.button_pressed = true
	_update_commands()

func _update_commands() -> void:
	$GameCommands/Play.disabled = button_group.get_pressed_button() == null

func _on_press_play() -> void:
	var selected := button_group.get_pressed_button() as GalaxyEntry
	if selected != null:
		selected_save.emit(saves_directory.path_join(selected.galaxy_dir))

func _on_press_createnew() -> void:
	if directory == null:
		refresh()
		if directory == null:
			return
	# Pick the first unused numbered name without overwriting an existing universe.
	var number := 1
	while directory.dir_exists("Universe %d" % number):
		number += 1
	var save := "Universe %d" % number
	var error := directory.make_dir(save)
	if error != OK:
		_show_error("Could not create universe: " + error_string(error))
		return
	refresh(save)

func _show_error(message: String) -> void:
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
