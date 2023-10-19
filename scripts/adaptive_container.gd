extends BoxContainer

@export var ratio = 1.0

@onready var parent = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	parent.connect("resized", _on_resized)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_resized():
	if parent.size.y * ratio >= parent.size.x && vertical == false:
		vertical = true
	elif parent.size.y * ratio < parent.size.x && vertical == true:
		vertical = false
