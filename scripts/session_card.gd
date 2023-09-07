extends Panel

signal open_pressed
signal delete_pressed

var session_name : String
var display_name : String

@onready var open_button = $SessionOptions/OpenButton
@onready var delete_button = $SessionOptions/DeleteButton
@onready var name_label = $SessionOptions/NameLabel
@onready var date_label = $SessionOptions/DateLabel
@onready var player_count_label = $SessionOptions/PlayerCountLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	open_button.connect("pressed", _on_open_button_pressed)
	delete_button.connect("pressed", _on_delete_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_open_button_pressed():
	emit_signal("open_pressed", session_name)

func _on_delete_button_pressed():
	emit_signal("delete_pressed", session_name)
	queue_free()

func set_session_name(new_session_name, new_display_name):
	session_name = new_session_name
	display_name = new_display_name
	name_label.text = display_name

func set_session_date(date):
	date_label.text = str(date.day) + "/" + str(date.month) + "/" + str(date.year)

func set_player_count(count):
	player_count_label.text = str(count)
