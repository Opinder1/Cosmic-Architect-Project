extends Screen

func _connect_signals() -> void:
	$Tabs/Singleplayer.selected_save.connect(_on_select_singleplayer_save)
	#$Tabs/Multiplayer.selected_save.connect(_on_select_multiplayer_save)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	
func _on_push(args: Dictionary) -> void:
	match args["tab"]:
		"singleplayer":
			$Tabs.current_tab = 0
			
		"multiplayer":
			$Tabs.current_tab = 1
			
		"options":
			$Tabs.current_tab = 2

func _on_select_singleplayer_save(save_directory: String) -> void:
	print("selected singleplayer save: ", save_directory)
	
	push_screens(["Game", "Controls"])

func _on_select_multiplayer_save(save_directory: String) -> void:
	print("selected multiplayer save: ", save_directory)
	
