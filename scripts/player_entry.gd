extends Button

signal selected

var is_selected = false

@onready var player_name_label = $Labels/PlayerNameLabel
@onready var local_score_label = $Labels/LocalScoreLabel
@onready var global_score_label = $Labels/GlobalScoreLabel
@onready var selection_draw = $SelectionDraw

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", _on_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_pressed():
	emit_signal("selected", get_index())

func select():
	is_selected = true
	draw_selection(is_selected)

func deselect():
	is_selected = false
	draw_selection(is_selected)

func show_local_score(visibility = true):
	local_score_label.visible = visibility

func show_global_score(visibility = true):
	global_score_label.visible = visibility

func set_player_name(player_name):
	player_name_label.text = player_name

func set_local_score(local_score):
	local_score_label.text = str(local_score)

func set_global_score(global_score):
	global_score_label.text = str(global_score)

func get_player_name():
	return player_name_label.text

func get_local_score():
	return int(local_score_label.text)

func get_global_score():
	return int(global_score_label.text)

func draw_selection(value = true):
	selection_draw.visible = value
