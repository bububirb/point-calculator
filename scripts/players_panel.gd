extends Control

signal cancel
signal save
signal player_selected

var names = {}
var scores = {}
var global_scores = {}
var matches = {}
var pinned = {}
var tally_function

@onready var player_item_list = $Panel/VBoxContainer/PlayerItemList
@onready var add_input = $Panel/VBoxContainer/PlayerControls/AddInput
@onready var add_button = $Panel/VBoxContainer/PlayerControls/AddButton
@onready var pin_button = $Panel/VBoxContainer/PlayerControls/PinButton

@onready var filter_input = $Panel/VBoxContainer/PlayerListControls/FilterInput
@onready var sort_button = $Panel/VBoxContainer/PlayerListControls/SortButton

@onready var remove_button = $Panel/VBoxContainer/BottomPlayerControls/RemoveButton
@onready var remove_confirmation_dialog = $RemoveConfirmationDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	load_player_item_list()
	
	add_input.connect("text_submitted", _on_add_input_text_submitted)
	add_button.connect("pressed", _on_add_button_pressed)
	pin_button.connect("pressed", _on_pin_button_pressed)
	
	sort_button.connect("pressed", _on_sort_button_pressed)
	filter_input.connect("text_changed", _on_filter_input_text_changed)
	
	remove_button.connect("pressed", _on_remove_button_pressed)
	player_item_list.connect("item_selected", _on_player_item_list_item_selected)
	remove_confirmation_dialog.connect("confirmed", _on_remove_confirmation_dialog_confirmed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_cancel_button_pressed():
	emit_signal("cancel")

func _on_save_button_pressed():
	save_player_data()

func _on_add_button_pressed():
	if add_input.text != "":
		var id = add_input.text
		if not get_ids_in_player_list().has(id):
			player_item_list.add_item(add_input.text)
			add_input.text = ""
			names[id] = id
			scores[id] = 0
			global_scores[id] = 0
			matches[id] = 0
			pinned[id] = false
			save_player_data()

func _on_add_input_text_submitted(new_text):
	if new_text != "":
		var id = new_text
		if not get_ids_in_player_list().has(id):
			player_item_list.add_item(new_text)
			add_input.text = ""
			names[id] = id
			scores[id] = 0
			global_scores[id] = 0
			matches[id] = 0
			pinned[id] = false
			save_player_data()

func _on_pin_button_pressed():
	var items = player_item_list.get_selected_items()
	if items.size() > 0:
		for idx in items:
			var id = player_item_list.get_player_name(idx)
			var is_pinned = false
			if pinned.has(id) and typeof(pinned[id]) == TYPE_BOOL:
				is_pinned = pinned[id]
			is_pinned = !is_pinned
			pinned[id] = is_pinned
			player_item_list.set_pinned(idx, is_pinned)
		save_player_data()
	player_item_list.sort_player_entries()

func _on_sort_button_pressed():
	player_item_list.toggle_reverse()

func _on_filter_input_text_changed(new_text):
	player_item_list.filter_options(new_text)

func _on_remove_button_pressed():
	if player_item_list.get_selected_items().size() > 0:
		remove_confirmation_dialog.show()

func _on_remove_confirmation_dialog_confirmed():
	remove_selected_players()

func remove_selected_players():
	var new_selection_idx
	for idx in player_item_list.get_selected_items():
		var id = player_item_list.get_player_name(idx)
		scores.erase(id)
		global_scores.erase(id)
		names.erase(id)
		pinned.erase(id)
		player_item_list.remove_item(idx)
		new_selection_idx = idx
		if new_selection_idx >= player_item_list.item_count:
			new_selection_idx -= 1
	save_player_data()
	if new_selection_idx >= 0:
		player_item_list.select(new_selection_idx)

func _on_player_item_list_item_selected(_index):
	var ids = []
	for idx in player_item_list.get_selected_items():
		ids.append(player_item_list.get_player_name(idx))
	emit_signal("player_selected", ids)

func _on_player_data_updated(sender = null):
	if sender != self:
		load_player_item_list()

func clear_selection():
	player_item_list.clear_selection()

func load_player_data():
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if not dir:
		Globals.setup_data_directories()
		dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(Globals.SESSION_DATA_PATH + "player_data.tres")
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
	
	if dir.file_exists("player_data.tres"):
		player_data_exists = true
	
	if player_data_exists:
		global_scores = Tally.tally_all_sessions(global_scores)
		matches = Tally.tally_matches(matches)

func load_player_item_list():
	load_player_data()
	load_player_stats()
	update_player_item_list()

func update_player_item_list():
	player_item_list.clear()
	for i in names.keys():
		player_item_list.add_item(names[i], pinned[i])

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
	for idx in player_item_list.item_count:
		ids.append(player_item_list.get_player_name(idx))
	return ids
