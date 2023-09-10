extends Control

signal cancel
signal save

var MATCH_DATA_PATH : String
var PLAYER_DATA_PATH : String

var names = {}
var scores = {}
var global_scores = {}
var tally_function

@onready var cancel_button = $Panel/VBoxContainer/TitleBar/CancelButton
@onready var save_button = $Panel/VBoxContainer/TitleBar/SaveButton
@onready var player_item_list = $Panel/VBoxContainer/AdaptiveContainer/PlayerItemList
@onready var session_graph = $Panel/VBoxContainer/AdaptiveContainer/ScrollContainer/SessionGraph
@onready var add_input = $Panel/VBoxContainer/PlayerListControls/AddInput
@onready var add_button = $Panel/VBoxContainer/PlayerListControls/AddButton
@onready var remove_button = $Panel/VBoxContainer/PlayerListControls/RemoveButton
@onready var tally_option_button = $Panel/VBoxContainer/TallyOptionsContainer/TallyOptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	MATCH_DATA_PATH = Globals.CURRENT_SESSION_PATH + "match_data/"
	PLAYER_DATA_PATH = Globals.SESSION_DATA_PATH #+ "player_data/" # Global player data refactor
	
	cancel_button.connect("pressed", _on_cancel_button_pressed)
	save_button.connect("pressed", _on_save_button_pressed)
	add_input.connect("text_submitted", _on_add_input_text_submitted)
	add_button.connect("pressed", _on_add_button_pressed)
	remove_button.connect("pressed", _on_remove_button_pressed)
	tally_option_button.connect("item_selected", _on_tally_option_button_item_selected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	names = {}
	for idx in player_item_list.item_count:
		var player_name = player_item_list.get_player_name(idx)
		names[player_name] = player_name
		var player_score = player_item_list.get_global_score(idx)
		scores[player_name] = player_score
	emit_signal("save", names, scores, tally_function.get_method())

func _on_add_button_pressed():
	if add_input.text != "":
		var id = add_input.text
		if not get_ids_in_player_list().has(id):
			player_item_list.add_item(add_input.text)
			session_graph.plot_point(0, add_input.text)
			add_input.text = ""

func _on_add_input_text_submitted(new_text):
	if new_text != "":
		var id = new_text
		if not get_ids_in_player_list().has(id):
			player_item_list.add_item(new_text)
			session_graph.plot_point(0, new_text)
			add_input.text = ""

func _on_remove_button_pressed():
	for idx in player_item_list.get_selected_items():
		var id = player_item_list.get_player_name(idx)
		scores.erase(id)
		names.erase(id)
		player_item_list.remove_item(idx)
		session_graph.remove(idx)
		var new_selection_idx = idx
		if new_selection_idx >= player_item_list.item_count:
			new_selection_idx -= 1
		if new_selection_idx >= 0:
			player_item_list.select(new_selection_idx)

func _on_tally_option_button_item_selected(index):
	tally_function = Tally.select_tally_option(index)
	global_scores = Tally.tally_all_sessions(global_scores)
	update_player_item_list()
	update_session_graph()

func load_tally_options():
	tally_option_button.clear()
	for tally_display_name in Tally.tally_display_names:
		tally_option_button.add_item(tally_display_name)
	tally_option_button.select(Tally.tally_options.find(tally_function))

func load_player_data():
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(PLAYER_DATA_PATH + "player_data.tres")
	else:
		player_data = ResourceLoader.load("res://resources/player_data/default_player_data.tres")
	names = player_data.names
	scores = player_data.scores
	global_scores = player_data.scores
	tally_function = Tally.get(player_data.tally_method)
	if tally_function:
		Tally.tally_function = tally_function
	load_tally_options()

func load_player_stats():
	for key in scores.keys():
		scores[key] = 0
	for key in global_scores.keys():
		global_scores[key] = 0
	
	var player_data_exists = false
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	#var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data_exists = true
		
#	dir = DirAccess.open(MATCH_DATA_PATH)
#	if not dir:
#		DirAccess.open(Globals.CURRENT_SESSION_PATH).make_dir("match_data")
#		dir = DirAccess.open(MATCH_DATA_PATH)
	var match_data : MatchData
	
	if player_data_exists:
		# Tally local scores
		for file in list_match_data():
			var match_scores = {}
			match_data = ResourceLoader.load(MATCH_DATA_PATH + file)
			
			for i in match_data.winning_scores.size():
				var id = match_data.winning_player_ids[i]
				if scores.has(id):
					scores[id] = scores[id] + match_data.winning_scores[i]
					match_scores[id] = match_data.winning_scores[i]
					# Todo: Record players participating in session
				
				id = match_data.losing_player_ids[i]
				if scores.has(id):
					scores[id] = scores[id] + match_data.losing_scores[i]
					match_scores[id] = match_data.losing_scores[i]
		# Tally global scores
		global_scores = Tally.tally_all_sessions(global_scores)
		update_session_graph()

func load_player_item_list():
	load_player_data()
	load_player_stats()
	update_player_item_list()

func update_player_item_list():
	player_item_list.clear()
	for i in names.keys():
		player_item_list.add_item(names[i], scores[i], global_scores[i])

func update_session_graph():
	session_graph.clear()
	session_graph.plot_set(global_scores.values(), names.values())

func list_match_data(session_name = null):
	var saved_match_data = []
	var dir
	if not session_name:
		dir = DirAccess.open(MATCH_DATA_PATH)
	else:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH + session_name + "/match_data/")
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

func get_ids_in_player_list():
	var ids = []
	for idx in player_item_list.item_count:
		ids.append(player_item_list.get_player_name(idx))
	return ids
