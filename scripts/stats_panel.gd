extends Control

signal cancel
signal save

signal player_selected

const ADVANCED_OPTIONS_MIN_HEIGHT = 36.0
const TWEEN_DURATION = 0.1

#var MATCH_DATA_PATH : String
var PLAYER_DATA_PATH : String

var names = {}
var scores = {}
var global_scores = {}
var matches = {}
var pinned = {}
var tally_function

@onready var player_stats_item_list = $VBoxContainer/AdaptiveContainer/PlayerStatsItemList
@onready var stats_graph = $VBoxContainer/AdaptiveContainer/StatsGraphContainer/ScrollContainer/StatsGraph
@onready var stats_graph_container = $VBoxContainer/AdaptiveContainer/StatsGraphContainer
@onready var tally_option_button = $VBoxContainer/AdvancedOptions/TallyOptionsContainer/TallyOptionButton
@onready var filter_input = $VBoxContainer/HBoxContainer/FilterInput
@onready var stats_graph_button = $VBoxContainer/HBoxContainer/StatsGraphButton
@onready var advanced_options_button = $VBoxContainer/HBoxContainer/AdvancedOptionsButton
@onready var advanced_options = $VBoxContainer/AdvancedOptions

# Called when the node enters the scene tree for the first time.
func _ready():
	PLAYER_DATA_PATH = Globals.SESSION_DATA_PATH
	
	load_player_stats_item_list()
	
	filter_input.connect("text_changed", _on_filter_input_text_changed)
	player_stats_item_list.connect("item_selected", _on_player_stats_item_list_item_selected)
	player_stats_item_list.connect("sorted", _on_player_stats_item_list_sorted)
	tally_option_button.connect("item_selected", _on_tally_option_button_item_selected)
	stats_graph_button.connect("toggled", _on_stats_graph_button_toggled)
	advanced_options_button.connect("toggled", _on_advanced_options_button_toggled)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	save_player_data()

func _on_filter_input_text_changed(new_text):
	player_stats_item_list.filter_options(new_text)

func _on_player_stats_item_list_item_selected(_index):
	var ids = []
	for idx in player_stats_item_list.get_selected_items():
		ids.append(player_stats_item_list.get_player_name(idx))
	emit_signal("player_selected", ids)

func _on_player_stats_item_list_sorted():
	update_stats_graph()

func _on_tally_option_button_item_selected(index):
	tally_function = Tally.select_tally_option(index)
	global_scores = Tally.tally_all_sessions(global_scores)
	save_player_data()
	update_player_stats_item_list()
	update_stats_graph()

func _on_stats_graph_button_toggled(button_pressed):
	if button_pressed:
		open_stats_graph()
	else:
		close_stats_graph()

func _on_advanced_options_button_toggled(button_pressed):
	if button_pressed:
		open_advanced_options()
	else:
		close_advanced_options()

func _on_player_data_updated(sender = null):
	if sender != self:
		load_player_stats_item_list()

func _on_match_data_updated(sender = null):
	if sender != self:
		load_player_stats_item_list()

func open_stats_graph():
	stats_graph_container.show()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(stats_graph_container, "size_flags_stretch_ratio", 1.0, TWEEN_DURATION)

func close_stats_graph():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(stats_graph_container, "size_flags_stretch_ratio", 0.0, TWEEN_DURATION)
	await tween.finished
	stats_graph_container.hide()

func open_advanced_options():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(advanced_options, "custom_minimum_size:y", ADVANCED_OPTIONS_MIN_HEIGHT, TWEEN_DURATION)

func close_advanced_options():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(advanced_options, "custom_minimum_size:y", 0.0, TWEEN_DURATION)

func clear_selection():
	player_stats_item_list.clear_selection()

func load_tally_options():
	tally_option_button.clear()
	for tally_display_name in Tally.tally_display_names:
		tally_option_button.add_item(tally_display_name)
	tally_option_button.select(Tally.tally_options.find(tally_function))

func load_player_data():
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if not dir:
		Globals.setup_data_directories()
		dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(PLAYER_DATA_PATH + "player_data.tres")
	else:
		player_data = ResourceLoader.load("res://resources/player_data/default_player_data.tres")
	names = player_data.names
	scores = player_data.scores
	global_scores = player_data.scores.duplicate()
	matches = player_data.matches
	pinned = player_data.pinned
	if not matches:
		matches = player_data.scores.duplicate()
		for key in matches.keys():
			matches[key] = 0
	if not pinned:
		pinned = player_data.scores.duplicate()
		for key in pinned.keys():
			pinned[key] = false
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
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if not dir:
		Globals.setup_data_directories()
		dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	#var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data_exists = true
	
	if player_data_exists:
		global_scores = Tally.tally_all_sessions(global_scores)
		matches = Tally.tally_matches(matches)

func load_player_stats_item_list():
	load_player_data()
	load_player_stats()
	update_player_stats_item_list()
	update_stats_graph()

func update_player_stats_item_list():
	player_stats_item_list.clear()
	for i in names.keys():
		player_stats_item_list.add_item(names[i], scores[i], global_scores[i], matches[i])

func update_stats_graph():
	stats_graph.clear()
	var sorted_scores = []
	var sorted_names = []
	for player_entry in player_stats_item_list.get_player_entries():
		sorted_scores.append(player_entry.get_global_score())
		sorted_names.append(player_entry.get_player_name())
	stats_graph.plot_set(sorted_scores, sorted_names)

func save_player_data():
	var player_data = PlayerData.new()
	player_data.names = names
	player_data.scores = global_scores
	player_data.matches = matches
	player_data.pinned = pinned
	player_data.tally_method = tally_function.get_method()
	emit_signal("save", player_data)

func get_ids_in_player_list():
	var ids = []
	for idx in player_stats_item_list.item_count:
		ids.append(player_stats_item_list.get_player_name(idx))
	return ids

func sort_dict(dict):
	var sorted_dict = {}
	var sorted_keys = dict.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		sorted_dict[key] = dict[key]
	return sorted_dict
