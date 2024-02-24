extends Control

@onready var game_list: Control = find_child("GameList")

@export var button_group = ButtonGroup.new()


func _ready():
	visibility_changed.connect(_on_visiblity_change)
	find_child("Play").pressed.connect(_on_press_play)
	find_child("Delete").pressed.connect(_on_press_delete)
	find_child("Rename").pressed.connect(_on_press_rename)
	find_child("CreateNew").pressed.connect(_on_press_createnew)
	
	
func _on_visiblity_change():
	if (!is_visible_in_tree()):
		return
		
	if !DirAccess.dir_exists_absolute("user://Universe"):
		DirAccess.make_dir_absolute("user://Universe")
	
	for game_dir in DirAccess.get_directories_at("user://Universe"):
		var game = GalaxyEntry.new()
		
		game.text = game_dir
		
		game.galaxy_dir = game_dir
		
		game.button_group = button_group
		
		game.toggle_mode = true
		
		game_list.add_child(game)


func _on_press_play():
	if (button_group.get_pressed_button()):
		print("play: ", button_group.get_pressed_button().galaxy_dir)
		
		Universe.start_galaxy()


func _on_press_delete():
	if (button_group.get_pressed_button()):
		print("delete: ", button_group.get_pressed_button().galaxy_dir)


func _on_press_rename():
	if (button_group.get_pressed_button()):
		print("rename: ", button_group.get_pressed_button().galaxy_dir)


func _on_press_createnew():
	print("createnew")
