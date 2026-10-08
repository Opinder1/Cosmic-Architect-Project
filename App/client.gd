extends ScreenStack

var instance_schematic := preload("res://App/Game/game_instance.tscn")
var current_game: Node
var error_dialog: AcceptDialog

func _ready() -> void:
	# Keep the menu alive as an overlay so it can pause an active game and return to it.
	$MainMenu.game_selected.connect(_on_game_selected)
	error_dialog = AcceptDialog.new()
	$MainMenu.add_child(error_dialog)
	set_screen($MenuScene)
	overlay_screen($MainMenu)

func _on_game_selected(save_directory: String, is_multiplayer: bool) -> void:
	if is_multiplayer:
		_show_error("Multiplayer sessions are not available yet.")
		return
	if not _close_game():
		set_screen($MenuScene)
		overlay_screen($MainMenu)
		return
	set_screen($LoadOverlay)
	var instance = instance_schematic.instantiate()
	var error: Error = instance.start(save_directory)
	if error != OK:
		instance.free()
		set_screen($MenuScene)
		overlay_screen($MainMenu)
		_show_error("Could not open universe: " + error_string(error))
		return
	current_game = instance
	current_game.return_to_menu.connect(_return_to_menu)
	$Game.add_child(current_game)
	$MenuScene/MeshInstance3D.hide()
	set_screen($Game)

func _close_game() -> bool:
	if not is_instance_valid(current_game):
		return true
	# Stop before freeing so the simulation can save and release its world state.
	var error: Error = current_game.stop()
	current_game.get_parent().remove_child(current_game)
	current_game.queue_free()
	current_game = null
	if error != OK:
		_show_error("Could not save universe: " + error_string(error))
		return false
	return true

func _return_to_menu() -> void:
	_close_game()
	set_screen($MenuScene)
	$MenuScene/MeshInstance3D.show()
	$MenuScene/Camera3D.make_current()
	overlay_screen($MainMenu)

func _show_error(message: String) -> void:
	error_dialog.dialog_text = message
	error_dialog.popup_centered()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("in_game_pause_open") and is_instance_valid(current_game):
		# The menu's visibility is the pause state; keep camera controls and HUD in sync.
		var paused: bool = not $MainMenu.visible
		if paused:
			overlay_screen($MainMenu)
		else:
			$MainMenu.hide()
		current_game.set_controls_active(not paused)
		current_game.get_node("HUD").visible = not paused
		get_viewport().set_input_as_handled()
