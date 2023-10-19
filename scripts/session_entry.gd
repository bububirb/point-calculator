extends Button

signal open_pressed
signal delete_pressed
signal moved_up
signal moved_down
signal selected

var is_selected = false
var session_name : String
var index : int
var display_name : String

@onready var open_button = $SessionOptions/OpenButton
@onready var delete_button = $SessionOptions/DeleteButton
@onready var name_label = $SessionOptions/NameLabel
@onready var date_label = $SessionOptions/DateLabel
@onready var player_count_label = $SessionOptions/PlayerCountLabel
@onready var move_up_button = $SessionOptions/MoveUpButton
@onready var move_down_button = $SessionOptions/MoveDownButton
@onready var selection_draw = $SelectionDraw

# Called when the node enters the scene tree for the first time.
func _ready():
	open_button.connect("pressed", _on_open_button_pressed)
	delete_button.connect("pressed", _on_delete_button_pressed)
	move_up_button.connect("pressed", _on_move_up_button_pressed)
	move_down_button.connect("pressed", _on_move_down_button_pressed)
	connect("pressed", _on_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_pressed():
	emit_signal("selected", get_index())

func _on_open_button_pressed():
	emit_signal("open_pressed", session_name)

func _on_delete_button_pressed():
	emit_signal("delete_pressed", session_name)
	queue_free()

func _on_move_up_button_pressed():
	emit_signal("moved_up", session_name, get_index())

func _on_move_down_button_pressed():
	emit_signal("moved_down", session_name, get_index())

func select():
	is_selected = true
	draw_selection(is_selected)

func deselect():
	is_selected = false
	draw_selection(is_selected)

func set_session_name(new_session_name, new_display_name):
	session_name = new_session_name
	display_name = new_display_name
	name_label.text = display_name

func set_session_date(date):
	date_label.text = str(date.day) + "/" + str(date.month) + "/" + str(date.year)

func set_session_index(value):
	index = value

func set_player_count(count):
	player_count_label.text = str(count)

func get_session_name():
	return session_name

func get_session_index():
	return index

func get_player_count():
	return player_count_label.text

func draw_selection(value = true):
	selection_draw.visible = value
