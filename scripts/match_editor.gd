extends Control

signal cancel
signal save

const TWEEN_DURATION = 0.25

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
var pinned = []

var overrides = []
var comments = ""

@onready var cancel_button = $EditorPanel/VBoxContainer/TitleBar/CancelButton
@onready var save_button = $EditorPanel/VBoxContainer/TitleBar/SaveButton
@onready var quota_input = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/Quota/QuotaInput
@onready var winning_player_inputs = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/TableContainer/WinningScoreTable/VBoxContainer/WinningPlayerInputs
@onready var losing_player_inputs = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/TableContainer/LosingScoreTable/VBoxContainer/LosingPlayerInputs
@onready var override_panel = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/OverridePanel
@onready var comments_input = $EditorPanel/VBoxContainer/ScrollContainer/VBoxContainer/CommentsPanel/CommentsInput
@onready var scroll_container = $EditorPanel/VBoxContainer/ScrollContainer

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
	
	override_panel.connect("override_added", _override_panel_override_added)
	override_panel.connect("override_player_changed", _override_panel_override_player_changed)
	override_panel.connect("override_score_changed", _override_panel_override_score_changed)
	override_panel.connect("override_relative_toggled", _override_panel_override_relative_toggled)
	override_panel.connect("override_deleted", _override_panel_override_deleted)
	
	comments_input.connect("text_changed", _comments_input_text_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	var match_data = MatchData.new()
	match_data.quota = quota
	match_data.winning_weights = winning_weights
	match_data.losing_weights = losing_weights
	match_data.winning_scores = winning_scores
	match_data.losing_scores = losing_scores
	match_data.winning_player_ids = winning_player_ids
	match_data.losing_player_ids = losing_player_ids
	match_data.overrides = overrides
	match_data.comments = comments
	emit_signal("save", edit_index, match_data)

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

func _override_panel_override_added():
	var override = {"player_id" : "", "score" : 0, "relative" : true}
	overrides.append(override)

func _override_panel_override_player_changed(index, player_id):
	overrides[index].player_id = player_id

func _override_panel_override_score_changed(index, score):
	overrides[index].score = score

func _override_panel_override_relative_toggled(index, relative):
	overrides[index].relative = relative

func _override_panel_override_deleted(index):
	overrides.remove_at(index)

func _comments_input_text_changed():
	comments = comments_input.text

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
	overrides = match_data.overrides
	if not overrides:
		overrides = []
	comments = match_data.comments
	if not comments:
		comments = ""
	
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
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(PLAYER_DATA_PATH + "player_data.tres")
	else:
		player_data = ResourceLoader.load("res://resources/player_data/default_player_data.tres")
	
	player_names = player_data.names.values()
	pinned = player_data.pinned
	if not pinned:
		pinned = player_data.scores.duplicate()
		for key in pinned.keys():
			pinned[key] = false
	pinned = pinned.values()
	
	quota_input.text = str(quota)
	
	for i in winning_player_inputs.get_child_count():
		winning_player_inputs.get_child(i).update_player_options(player_names, pinned, winning_player_ids[i])
	for i in losing_player_inputs.get_child_count():
		losing_player_inputs.get_child(i).update_player_options(player_names, pinned, losing_player_ids[i])
	
	override_panel.player_names = player_names
	override_panel.pinned = pinned
	override_panel.clear_overrides()
	override_panel.load_overrides(overrides)
	
	comments_input.text = comments
	
	open_panels()

func refresh_player_options():
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(PLAYER_DATA_PATH + "player_data.tres")
	else:
		player_data = ResourceLoader.load("res://resources/player_data/default_player_data.tres")
	player_names = player_data.names.values()
	pinned = player_data.pinned
	if not pinned:
		pinned = player_data.scores.duplicate()
		for key in pinned.keys():
			pinned[key] = false
	pinned = pinned.values()
	for i in winning_player_inputs.get_child_count():
		winning_player_inputs.get_child(i).refresh_player_options(player_names, pinned)
	for i in losing_player_inputs.get_child_count():
		losing_player_inputs.get_child(i).refresh_player_options(player_names, pinned)
	override_panel.player_names = player_names
	override_panel.pinned = pinned
	override_panel.refresh_player_options()

# Experimental: Reset editor parameters
func reset():
	scroll_container.scroll_vertical = 0
	set_loading(true)
	override_panel.clear_overrides()
	comments_input.text = ""
	comments_input.modulate.a = 0.0

func open_panels():
	set_loading(false)

func set_loading(loading):
	for input in winning_player_inputs.get_children():
		input.set_loading(loading)
	for input in losing_player_inputs.get_children():
		input.set_loading(loading)
	create_tween().tween_property(comments_input, "modulate:a", 1.0, TWEEN_DURATION)
