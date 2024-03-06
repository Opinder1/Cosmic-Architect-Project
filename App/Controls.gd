extends Screen

func _connect_signals() -> void:
	$Back.pressed.connect(_on_back)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	
func _on_back() -> void:
	pop_screens()
