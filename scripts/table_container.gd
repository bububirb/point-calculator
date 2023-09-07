extends BoxContainer

var ratio = 1.2

@onready var scroll_container = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	scroll_container.connect("resized", _on_resized)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_resized():
	var window_size = DisplayServer.window_get_size()
	if window_size.y * 1.2 >= window_size.x && vertical == false:
		vertical = true
	elif window_size.y * 1.2 < window_size.x && vertical == true:
		vertical = false
