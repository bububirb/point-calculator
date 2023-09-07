extends Control

signal cancel
signal save

var MATCH_DATA_PATH : String
var PLAYER_DATA_PATH : String

var edit_index = 0

var quota = 100

var winning_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
var winning_scores = [20, 20, 20, 20, 20]
var winning_remainders = [0.0, 0.0, 0.0, 0.0, 0.0]
var winning_player_ids = ["", "", "", "", ""]

var losing_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
var losing_weights_inverted = [1.0, 1.0, 1.0, 1.0, 1.0]
var losing_scores = [-20, -20, -20, -20, -20]
var losing_remainders = [0.0, 0.0, 0.0, 0.0, 0.0]
var losing_player_ids = ["", "", "", "", ""]

var player_names = []

@onready var cancel_button = $EditorPanel/VBoxContainer/TitleBar/CancelButton
@onready var save_button = $EditorPanel/VBoxContainer/TitleBar/SaveButton
@onready var quota_input = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/Quota/QuotaInput
@onready var winning_player_inputs = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/TableContainer/WinningScoreTable/VBoxContainer/WinningPlayerInputs
@onready var losing_player_inputs = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/TableContainer/LosingScoreTable/VBoxContainer/LosingPlayerInputs

# Called when the node enters the scene tree for the first time.
func _ready():
	MATCH_DATA_PATH = Globals.CURRENT_SESSION_PATH + "match_data/"
	PLAYER_DATA_PATH = Globals.SESSION_DATA_PATH #+ "player_data/" # Global player data refactor
	
	cancel_button.connect("pressed", _on_cancel_button_pressed)
	save_button.connect("pressed", _on_save_button_pressed)
	
	quota_input.connect("text_changed", _on_quota_input_text_changed)
	for player_input in winning_player_inputs.get_children():
		player_input.connect("weight_changed", _on_winning_player_input_weight_changed)
		player_input.connect("player_changed", _on_winning_player_changed)
	for player_input in losing_player_inputs.get_children():
		player_input.connect("weight_changed", _on_losing_player_input_weight_changed)
		player_input.connect("player_changed", _on_losing_player_changed)
		player_input.set_score(-20)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	emit_signal("save", edit_index, winning_scores, losing_scores, quota, winning_weights, losing_weights, winning_player_ids, losing_player_ids)

func _on_quota_input_text_changed(new_text):
	if new_text == "":
		new_text = "100"
	set_quota(float(new_text))

func set_quota(value):
	quota = value
	update_score()

func get_player_options():
	var player_options = []
	for player_input in winning_player_inputs.get_children():
		player_options.append(player_input.player_option)
	for player_input in losing_player_inputs.get_children():
		player_options.append(player_input.player_option)
	return player_options

func _on_winning_player_input_weight_changed(index, weight):
	winning_weights[index] = weight
	update_winning_score()

func _on_losing_player_input_weight_changed(index, weight):
	losing_weights[index] = weight
	update_losing_score()

func _on_winning_player_changed(index, player_id):
	winning_player_ids[index] = player_id

func _on_losing_player_changed(index, player_id):
	losing_player_ids[index] = player_id

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
		if losing_weights[i] == 0:
			losing_weights_inverted[i] = 0.0
		else:
			losing_weights_inverted[i] = 1.0 / losing_weights[i]
	var total_weight = 0.0
	for i in losing_weights_inverted:
		total_weight += i
	var temp_scores = [0.0, 0.0, 0.0, 0.0, 0.0]
	var total_score = 0
	
	for i in losing_weights_inverted.size():
		if total_weight == 0:
			temp_scores[i] = 0
		else:
			temp_scores[i] = losing_weights_inverted[i] / total_weight * losing_quota
		losing_scores[i] = ceil(temp_scores[i])
		losing_remainders[i] = losing_scores[i] - temp_scores[i]
		total_score += losing_scores[i]
	var total_remainder = 0.0
	if total_weight != 0:
		total_remainder = total_score - losing_quota
	
	for i in total_remainder:
		var highest_remainder = 0.0
		var selected_index = 0
		# Select score with the highest remainder
		for j in losing_weights_inverted.size():
			if losing_remainders[losing_weights_inverted.size() - 1 - j] > highest_remainder:
				highest_remainder = losing_remainders[losing_weights_inverted.size() - 1 - j]
				selected_index = losing_weights_inverted.size() - 1 - j
		# Adjust selected score
		losing_scores[selected_index] -= 1
		losing_remainders[selected_index] = 0 # Set remainder to 0 after adjustment
	
	for i in losing_weights_inverted.size():
		# Negative 0 workaround
		if losing_scores[i] == 0:
			losing_scores[i] = 0
		losing_player_inputs.get_child(i).set_score(losing_scores[i])

func update_score():
	update_winning_score()
	update_losing_score()

func load_match_data():
	var new = true
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir:
		DirAccess.open(Globals.CURRENT_SESSION_PATH).make_dir("match_data")
		dir = DirAccess.open(MATCH_DATA_PATH)
	var match_data : MatchData
	if dir.file_exists("match_data_" + str(edit_index) + ".tres"):
		match_data = ResourceLoader.load(MATCH_DATA_PATH + "match_data_" + str(edit_index) + ".tres")
		new = false
	else:
		match_data = ResourceLoader.load("res://resources/match_data/default_match_data.tres")
	quota = match_data.quota
	winning_weights = match_data.winning_weights
	winning_scores = match_data.winning_scores
	winning_player_ids = match_data.winning_player_ids
	losing_weights = match_data.losing_weights
	losing_scores = match_data.losing_scores
	losing_player_ids = match_data.losing_player_ids
	
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
			winning_player_inputs.get_child(i).set_weight(winning_weights[i])
			winning_player_inputs.get_child(i).set_score(winning_scores[i])
		for i in losing_player_inputs.get_child_count():
			losing_player_inputs.get_child(i).set_weight(losing_weights[i])
			losing_player_inputs.get_child(i).set_score(losing_scores[i])

func load_player_data():
	var new = true
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(PLAYER_DATA_PATH + "player_data.tres")
		new = false
	else:
		player_data = ResourceLoader.load("res://resources/player_data/default_player_data.tres")
	player_names = player_data.names.values()
	
	if not new:
		quota_input.text = str(quota)
		for i in winning_player_inputs.get_child_count():
			winning_player_inputs.get_child(i).update_player_options(player_names, winning_player_ids[i])
		for i in losing_player_inputs.get_child_count():
			losing_player_inputs.get_child(i).update_player_options(player_names, losing_player_ids[i])
