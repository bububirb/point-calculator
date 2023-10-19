extends HBoxContainer

signal weight_changed
signal player_changed

const TWEEN_DURATION = 0.25

@onready var player_option = $PanelContainer/Player/PlayerOption
@onready var player_reset_button = $PanelContainer/Player/PlayerResetButton
@onready var weight_input = $WeightInput
@onready var score_label = $ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	player_option.connect("item_selected", _on_player_option_item_selected)
	player_reset_button.connect("pressed", _on_player_reset_button_pressed)
	weight_input.connect("text_changed", _on_weight_input_text_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_weight_input_text_changed(new_text):
	if new_text == "":
		new_text = "1"
	var weight = float(new_text)
	emit_signal("weight_changed", get_index(), weight)

func _on_player_option_item_selected(index):
	var player_id = player_option.get_item_text(index)
	emit_signal("player_changed", get_index(), player_id)

func _on_player_reset_button_pressed():
	var player_id = ""
	player_option.select(-1)
	emit_signal("player_changed", get_index(), player_id)

func set_weight(weight):
	weight_input.text = str(weight)

func set_score(score):
	if score > 0:
		score_label.text = "+" + str(score)
	else:
		score_label.text = str(score)

func set_loading(loading):
	if loading:
		modulate.a = 0.0
	else:
		create_tween().tween_property(self, "modulate:a", 1.0, TWEEN_DURATION)

func update_player_options(player_names, pinned, selection_id):
	player_option.clear()
	for i in player_names.size():
		player_option.add_item(player_names[i], pinned[i])
	var selection = player_names.find(selection_id)
	if selection < player_option.item_count:
		player_option.select(selection)
	else:
		player_option.select(-1)
	player_option.sort_options()

func refresh_player_options(player_names, pinned):
	player_option.clear(false)
	for i in player_names.size():
		player_option.add_item(player_names[i], pinned[i])
	player_option.sort_options()
