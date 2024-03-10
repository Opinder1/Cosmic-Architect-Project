extends Control

@onready var game_list: Control = find_child("GameList")

@export var button_group = ButtonGroup.new()

@export var save_directory: String = "user://Universe"

var directory : DirAccess

signal selected_save(save_directory: String)

func _connect_signals() -> void:
	visibility_changed.connect(_on_visiblity_change)
	$GameCommands/Play.pressed.connect(_on_press_play)
	$GameCommands/Delete.pressed.connect(_on_press_delete)
	$GameCommands/Rename.pressed.connect(_on_press_rename)
	$GameCommands/CreateNew.pressed.connect(_on_press_createnew)

func _ready() -> void:
	_connect_signals()
	
	create()

func _on_visiblity_change() -> void:
	if (!is_visible_in_tree()):
		return
		
	refresh();

func create() -> void:
	if !DirAccess.dir_exists_absolute(save_directory):
		DirAccess.make_dir_absolute(save_directory)

func refresh() -> void:
	directory = DirAccess.open(save_directory)
	
	for child in game_list.get_children():
		game_list.remove_child(child)
	
	for game_dir in directory.get_directories_at(save_directory):
		var game = GalaxyEntry.new()
		
		game.text = game_dir
		
		game.galaxy_dir = game_dir
		
		game.button_group = button_group
		
		game.toggle_mode = true
		
		game_list.add_child(game)

func _on_press_play() -> void:
	if (button_group.get_pressed_button()):
		var save_directory: String = button_group.get_pressed_button().galaxy_dir
		
		print("play: ", button_group.get_pressed_button().galaxy_dir)
		
		selected_save.emit(save_directory)

func _on_press_delete() -> void:
	if (button_group.get_pressed_button()):
		print("delete: ", button_group.get_pressed_button().galaxy_dir)

func _on_press_rename() -> void:
	if (button_group.get_pressed_button()):
		print("rename: ", button_group.get_pressed_button().galaxy_dir)

func _on_press_createnew() -> void:
	print("createnew")
	
	directory.make_dir(var_to_str(randi_range(1111111,9999999)))
	refresh()
