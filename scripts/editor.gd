extends Control

signal cancel
signal save

const SAVE_PATH = "user://match_data/"

var edit_index = 0

var quota = 100

var winning_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
var winning_scores = [20, 20, 20, 20, 20]
var winning_remainders = [0.0, 0.0, 0.0, 0.0, 0.0]

var losing_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
var losing_weights_inverted = [1.0, 1.0, 1.0, 1.0, 1.0]
var losing_scores = [-20, -20, -20, -20, -20]
var losing_remainders = [0.0, 0.0, 0.0, 0.0, 0.0]

@onready var cancel_button = $EditorPanel/VBoxContainer/HBoxContainer/CancelButton
@onready var save_button = $EditorPanel/VBoxContainer/HBoxContainer/SaveButton
@onready var quota_input = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/Quota/QuotaInput
@onready var winning_player_inputs = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/TableContainer/WinningScoreTable/VBoxContainer/WinningPlayerInputs
@onready var losing_player_inputs = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/TableContainer/LosingScoreTable/VBoxContainer/LosingPlayerInputs

# Called when the node enters the scene tree for the first time.
func _ready():
	cancel_button.connect("pressed", _on_cancel_button_pressed)
	save_button.connect("pressed", _on_save_button_pressed)
	
	quota_input.connect("text_changed", _on_quota_input_text_changed)
	for player_input in winning_player_inputs.get_children():
		player_input.connect("weight_changed", _on_winning_player_input_weight_changed)
	for player_input in losing_player_inputs.get_children():
		player_input.connect("weight_changed", _on_losing_player_input_weight_changed)
		player_input.set_score(-20)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	emit_signal("save", edit_index, winning_scores, losing_scores, quota, winning_weights, losing_weights)

func _on_quota_input_text_changed(new_text):
	if new_text == "":
		new_text = "100"
	set_quota(float(new_text))

func set_quota(value):
	quota = value
	update_score()

func _on_winning_player_input_weight_changed(index, weight):
	winning_weights[index] = weight
	update_winning_score()

func _on_losing_player_input_weight_changed(index, weight):
	losing_weights[index] = weight
	update_losing_score()

func update_winning_score():
	var total_weight = 0.0
	for i in winning_weights:
		total_weight += i
	var temp_scores = [0.0, 0.0, 0.0, 0.0, 0.0]
	var total_score = 0
	
	for i in winning_weights.size():
		temp_scores[i] = winning_weights[i] / total_weight * quota
		winning_scores[i] = floor(temp_scores[i])
		winning_remainders[i] = temp_scores[i] - winning_scores[i]
		total_score += winning_scores[i]
	var total_remainder = quota - total_score
	
	for i in total_remainder:
		var highest_remainder = 0.0
		var selected_index = 0
		# Select score with the highest remainder
		for j in winning_weights.size():
			if winning_remainders[j] > highest_remainder:
				highest_remainder = winning_remainders[j]
				selected_index = j
		# Adjust selected score
		winning_scores[selected_index] += 1
		winning_remainders[selected_index] = 0 # Set remainder to 0 after adjustment
	
	for i in winning_weights.size():
		winning_player_inputs.get_child(i).set_score(winning_scores[i])

func update_losing_score():
	var losing_quota = -quota
	for i in losing_weights_inverted.size():
		losing_weights_inverted[i] = 1.0 / losing_weights[i]
	var total_weight = 0.0
	for i in losing_weights_inverted:
		total_weight += i
	var temp_scores = [0.0, 0.0, 0.0, 0.0, 0.0]
	var total_score = 0
	
	for i in losing_weights_inverted.size():
		temp_scores[i] = losing_weights_inverted[i] / total_weight * losing_quota
		losing_scores[i] = ceil(temp_scores[i])
		losing_remainders[i] = losing_scores[i] - temp_scores[i]
		total_score += losing_scores[i]
	var total_remainder = total_score - losing_quota
	
	for i in total_remainder:
		var highest_remainder = 0.0
		var selected_index = 0
		# Select score with the highest remainder
		for j in losing_weights_inverted.size():
			if losing_remainders[j] > highest_remainder:
				highest_remainder = losing_remainders[j]
				selected_index = j
		# Adjust selected score
		losing_scores[selected_index] -= 1
		losing_remainders[selected_index] = 0 # Set remainder to 0 after adjustment
	
	for i in losing_weights_inverted.size():
		losing_player_inputs.get_child(i).set_score(losing_scores[i])

func update_score():
	update_winning_score()
	update_losing_score()

func load_match_data():
	var new = true
	var dir = DirAccess.open(SAVE_PATH)
	if not dir:
		DirAccess.open("user://").make_dir("match_data")
		dir = DirAccess.open(SAVE_PATH)
	var match_data : MatchData
	if dir.file_exists("match_data_" + str(edit_index) + ".tres"):
		match_data = ResourceLoader.load(SAVE_PATH + "match_data_" + str(edit_index) + ".tres")
		new = false
	else:
		match_data = ResourceLoader.load("res://resources/match_data/default_match_data.tres")
	quota = match_data.quota
	winning_weights = match_data.winning_weights
	winning_scores = match_data.winning_scores
	losing_weights = match_data.losing_weights
	losing_scores = match_data.losing_scores
	
	if new:
		quota_input.text = ""
		for i in winning_player_inputs.get_child_count():
			winning_player_inputs.get_child(i).set_weight("")
			winning_player_inputs.get_child(i).set_score(20)
		for i in losing_player_inputs.get_child_count():
			losing_player_inputs.get_child(i).set_weight("")
			losing_player_inputs.get_child(i).set_score(-20)
	
	if not new:
		quota_input.text = str(quota)
		for i in winning_player_inputs.get_child_count():
			winning_player_inputs.get_child(i).set_weight(match_data.winning_weights[i])
			winning_player_inputs.get_child(i).set_score(match_data.winning_scores[i])
		for i in losing_player_inputs.get_child_count():
			losing_player_inputs.get_child(i).set_weight(match_data.losing_weights[i])
			losing_player_inputs.get_child(i).set_score(match_data.losing_scores[i])
