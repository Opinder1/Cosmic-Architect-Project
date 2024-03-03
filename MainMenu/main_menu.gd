extends Screen

func _connect_signals() -> void:
	$Tabs/Singleplayer.selected_save.connect(_on_select_save)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()

func _on_select_save(save_directory : String) -> void:
	print("selected save: ", save_directory)
	
	set_screens(["InGame", "InGameBackground"])
