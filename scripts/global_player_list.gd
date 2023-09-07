extends Control

signal cancel
signal save

var MATCH_DATA_PATH : String
var PLAYER_DATA_PATH : String

var names = {}
var scores = {}
#var scores_accumulated = []

@onready var cancel_button = $Panel/VBoxContainer/TitleBar/CancelButton
@onready var save_button = $Panel/VBoxContainer/TitleBar/SaveButton
@onready var player_item_list = $Panel/VBoxContainer/AdaptiveContainer/PlayerItemList
#@onready var session_graph = $Panel/VBoxContainer/AdaptiveContainer/SessionGraph
@onready var add_input = $Panel/VBoxContainer/PlayerListControls/AddInput
@onready var add_button = $Panel/VBoxContainer/PlayerListControls/AddButton
@onready var remove_button = $Panel/VBoxContainer/PlayerListControls/RemoveButton

# Called when the node enters the scene tree for the first time.
func _ready():
	MATCH_DATA_PATH = Globals.CURRENT_SESSION_PATH + "match_data/"
	PLAYER_DATA_PATH = Globals.SESSION_DATA_PATH #+ "player_data/" # Global player data refactor
	
	cancel_button.connect("pressed", _on_cancel_button_pressed)
	save_button.connect("pressed", _on_save_button_pressed)
	add_input.connect("text_submitted", _on_add_input_text_submitted)
	add_button.connect("pressed", _on_add_button_pressed)
	remove_button.connect("pressed", _on_remove_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	names = {}
	for idx in player_item_list.item_count / player_item_list.max_columns:
		var player_name = player_item_list.get_item_text(idx * player_item_list.max_columns)
		names[hash(player_name)] = player_name
		var player_score = int(player_item_list.get_item_text(idx * player_item_list.max_columns + 1))
		scores[hash(player_name)] = player_score
	emit_signal("save", names, scores)

func _on_add_button_pressed():
	if add_input.text != "":
		var id = hash(add_input.text)
		if not get_ids_in_player_list().has(id):
			player_item_list.add_item(add_input.text)
			player_item_list.add_item("")
			#session_graph.plot_point(0, add_input.text)
			add_input.text = ""

func _on_add_input_text_submitted(new_text):
	if new_text != "":
		var id = hash(new_text)
		if not get_ids_in_player_list().has(id):
			player_item_list.add_item(new_text)
			player_item_list.add_item("")
			#session_graph.plot_point(0, new_text)
			add_input.text = ""

func _on_remove_button_pressed():
	for idx in player_item_list.get_selected_items():
		var id = player_item_list.get_item_text(idx)
		scores.erase(hash(id))
		names.erase(hash(id))
		player_item_list.remove_item(idx)
		player_item_list.remove_item(idx)
		#session_graph.remove(idx / player_item_list.max_columns)
		var new_selection_idx = idx
		if new_selection_idx >= player_item_list.item_count:
			new_selection_idx -= player_item_list.max_columns
		if new_selection_idx >= 0:
			player_item_list.select(new_selection_idx)

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

func load_player_stats():
	for key in scores.keys():
		scores[key] = 0
	
	var player_data_exists = false
	var dir = DirAccess.open(PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	#var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data_exists = true
		
	dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir:
		DirAccess.open(Globals.CURRENT_SESSION_PATH).make_dir("match_data")
		dir = DirAccess.open(MATCH_DATA_PATH)
	var match_data : MatchData
	
	if player_data_exists:
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
		#session_graph.clear()
		#session_graph.plot_set(scores.values(), names.values())
#			scores_accumulated.append(scores.duplicate())
#	print(scores_accumulated) # Todo: Session Graph

func load_player_item_list():
	load_player_data()
	load_player_stats()
	player_item_list.clear()
	for i in names.keys():
		player_item_list.add_item(names[i])
		player_item_list.add_item("") #str(scores[i])) # No scores loaded
	for i in names.keys().size():
		player_item_list.set_item_selectable(i * player_item_list.max_columns + 1, false)

func list_match_data():
	var saved_match_data = []
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

func get_ids_in_player_list():
	var ids = []
	for idx in player_item_list.item_count / player_item_list.max_columns:
		ids.append(hash(player_item_list.get_item_text(idx * player_item_list.max_columns)))
	return ids
