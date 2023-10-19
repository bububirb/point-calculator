extends Button

var pinned = false
var pin_icon = preload("res://assets/icons/pin.svg")

@onready var id = get_index()

func _ready():
	if pinned:
		icon = pin_icon
