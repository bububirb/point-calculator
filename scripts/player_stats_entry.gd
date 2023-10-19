extends Button

signal selected

var is_selected = false

const TWEEN_DURATION = 0.4
const MIN_HEIGHT = 32.0

@onready var player_name_label = $Labels/PlayerNameLabel
@onready var local_score_label = $Labels/LocalScoreLabel
@onready var global_score_label = $Labels/GlobalScoreLabel
@onready var matches_label = $Labels/MatchesLabel
@onready var wins_label = $Labels/WinsLabel
@onready var losses_label = $Labels/LossesLabel
@onready var selection_draw = $SelectionDraw

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", _on_pressed)
#	expand()

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

func show_matches(visibility = true):
	matches_label.visible = visibility

func show_wins(visibility = true):
	wins_label.visible = visibility

func show_losses(visibility = true):
	losses_label.visible = visibility

func set_player_name(player_name):
	player_name_label.text = player_name

func set_local_score(local_score):
	local_score_label.text = str(local_score)

func set_global_score(global_score):
	global_score_label.text = str(global_score)

func set_matches(matches):
	matches_label.text = str(matches)

func set_wins(wins):
	wins_label.text = str(wins)

func set_losses(losses):
	losses_label.text = str(losses)

func get_player_name():
	return player_name_label.text

func get_local_score():
	return int(local_score_label.text)

func get_global_score():
	return int(global_score_label.text)

func get_matches():
	return int(matches_label.text)

func get_wins():
	return int(wins_label.text)

func get_losses():
	return int(losses_label.text)

func draw_selection(value = true):
	selection_draw.visible = value

func expand():
	modulate.a = 0.0
	custom_minimum_size.y = 16.0
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT).set_parallel()
	tween.tween_property(self, "custom_minimum_size:y", MIN_HEIGHT, TWEEN_DURATION)
	tween.tween_property(self, "modulate:a", 1.0, TWEEN_DURATION)
