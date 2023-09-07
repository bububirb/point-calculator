extends HBoxContainer

signal weight_changed
signal player_changed

@onready var weight_input = $WeightInput
@onready var score_label = $ScoreLabel
@onready var player_option = $PanelContainer/Player/PlayerOption
@onready var player_reset_button = $PanelContainer/Player/PlayerResetButton

# Called when the node enters the scene tree for the first time.
func _ready():
	weight_input.connect("text_changed", _on_weight_input_text_changed)
	player_option.connect("item_selected", _on_player_option_item_selected)
	player_reset_button.connect("pressed", _on_player_reset_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_weight_input_text_changed(new_text):
	if new_text == "":
		new_text = "1"
	var weight = float(new_text)
	emit_signal("weight_changed", get_index(), weight)

func _on_player_option_item_selected(index):
	var player_id = int(player_option.get_item_id(index))
	emit_signal("player_changed", get_index(), player_id)

func _on_player_reset_button_pressed():
	var player_id = -1
	player_option.select(player_id)
	emit_signal("player_changed", get_index(), player_id)

func set_weight(weight):
	weight_input.text = str(weight)

func set_score(score):
	if score > 0:
		score_label.text = "+" + str(score)
	else:
		score_label.text = str(score)

func update_player_options(player_names, selection_id):
	player_option.clear()
	for player_name in player_names:
		player_option.add_item(player_name, hash(player_name))
	var selection = player_option.get_item_index(selection_id)
	if selection < player_option.item_count:
		player_option.select(selection)
	else:
		player_option.select(-1)
