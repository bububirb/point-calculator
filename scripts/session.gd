extends Control

signal tween_finished

var MATCH_DATA_PATH : String
var PLAYER_DATA_PATH : String

var tween_duration = 0.4

var session_name = "session"

@onready var main_container = $MainContainer
@onready var card_list = $MainContainer/CardList
@onready var editor = $MainContainer/Editor
@onready var new_button = $MainContainer/MenuBar/HBoxContainer/NewButton
@onready var menu_bar = $MainContainer/MenuBar
@onready var player_list = $MainContainer/PlayerList
@onready var players_button = $MainContainer/MenuBar/HBoxContainer/PlayersButton
@onready var session_option = $MainContainer/MenuBar/HBoxContainer/SessionOption

@onready var menu_bar_height = menu_bar.size.y

func _init():
	session_name = Globals.current_session_name
	var dir = DirAccess.open(Globals.CURRENT_SESSION_PATH)
	if not dir:
		DirAccess.open(Globals.SESSION_DATA_PATH).make_dir(session_name)
	MATCH_DATA_PATH = Globals.CURRENT_SESSION_PATH + "match_data/"
	PLAYER_DATA_PATH = Globals.SESSION_DATA_PATH #+ "player_data/" # Global player data refactor

func _ready():
	if OS.get_name() == "Windows":
		pass
	elif OS.get_name() == "Android":
		resized.connect(_fit_display_cutouts)
		_fit_display_cutouts()
	
	new_button.connect("pressed", _on_new_button_pressed)
	players_button.connect("pressed", _on_players_button_pressed)
	
	card_list.connect("card_edit", _on_card_list_card_edit)
	card_list.connect("card_delete", _on_card_list_card_delete)
	card_list.connect("card_move_up", _on_card_list_card_move_up)
	card_list.connect("card_move_down", _on_card_list_card_move_down)
	card_list.connect("card_duplicate", _on_card_list_card_duplicate)
	editor.connect("cancel", _on_editor_cancel)
	editor.connect("save", _on_editor_save)
	player_list.connect("cancel", _on_player_list_cancel)
	player_list.connect("save", _on_player_list_save)
	
	session_option.connect("item_selected", _on_session_option_item_selected)
	
	load_match_data()
	load_data()
	load_session_options()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _fit_display_cutouts():
	main_container.set_position(DisplayServer.get_display_safe_area().position)
	main_container.set_size(DisplayServer.get_display_safe_area().size)

func _on_card_list_card_edit(index):
	open_editor()
#	# Deferred editor loading
#	await tween_finished
	set_edit_index(index)
	editor.load_match_data()
	editor.load_player_data()

func _on_card_list_card_delete(index):
	var saved_match_data = list_match_data()
	if saved_match_data:
		OS.move_to_trash(ProjectSettings.globalize_path(MATCH_DATA_PATH + saved_match_data[index]))
		reorder_match_data()

func _on_card_list_card_move_up(index):
	move_match_data(index, -1)

func _on_card_list_card_move_down(index):
	move_match_data(index, 1)

func _on_card_list_card_duplicate(index):
	var list = list_match_data()
	if index < list.size():
		var match_data = ResourceLoader.load(MATCH_DATA_PATH + list[index])
		save_match_data(match_data, list_match_data().size())
		card_list.load_card(match_data)

func set_edit_index(index):
	editor.edit_index = index

func _on_editor_cancel():
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir.file_exists("match_data_" + str(editor.edit_index) + ".tres"):
		card_list.delete_card(editor.edit_index)
	close_editor()

func _on_editor_save(edit_index, match_data : MatchData):
	card_list.set_card_scores(edit_index, match_data.winning_scores, match_data.losing_scores)
	save_match_data(match_data, edit_index)
	close_editor()

func save_match_data(match_data, index):
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir:
		DirAccess.open(Globals.CURRENT_SESSION_PATH).make_dir("match_data")
	ResourceSaver.save(match_data, MATCH_DATA_PATH + "match_data_" + str(index) + ".tres")

func load_data():
	var session_data = Globals.load_session_data(session_name)
	if session_data:
		Globals.current_session_display_name = session_data.display_name

func _on_player_list_cancel():
	close_player_list()

func _on_player_list_save(player_data):
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if dir:
		ResourceSaver.save(player_data, Globals.SESSION_DATA_PATH + "player_data.tres")
	close_player_list()

func _on_session_option_item_selected(index):
	if index == 0:
		get_tree().change_scene_to_packed(load("res://scenes/sessions_list.tscn"))
	else:
		Globals.load_session(Globals.list_session_folders()[index - 2])

func open_editor():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(editor, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", 0.0, tween_duration)
	new_button.disabled = true
#	# For deferred editor loading
#	await tween.finished
#	emit_signal("tween_finished")

func close_editor():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(editor, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", menu_bar_height, tween_duration)
	new_button.disabled = false

func open_player_list():
	players_button.disabled = true
	player_list.load_player_item_list()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(player_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", 0.0, tween_duration)

func close_player_list():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(player_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(card_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(menu_bar, "custom_minimum_size:y", menu_bar_height, tween_duration)
	players_button.disabled = false

func list_match_data():
	var saved_match_data = []
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

func load_match_data():
	for file in list_match_data():
		var match_data = ResourceLoader.load(MATCH_DATA_PATH + file)
		card_list.load_card(match_data)

func load_session_options():
	for session in Globals.list_session_folders():
		var session_data = Globals.load_session_data(session)
		if session_data:
			session_option.add_item(session_data.display_name)
		else:
			session_option.add_item(session)
	session_option.select(Globals.list_session_folders().find(session_name) + 2)

func _on_new_button_pressed():
	card_list.add_card()
	new_button.disabled = true

func _on_players_button_pressed():
	open_player_list()
	players_button.disabled = true

func reorder_match_data():
	var dir = DirAccess.open(MATCH_DATA_PATH)
	var saved_match_data = list_match_data()
	for i in saved_match_data.size():
		dir.rename(saved_match_data[i], "match_data_" + str(i) + ".tres")

func move_match_data(index : int, offset : int):
	var dir = DirAccess.open(MATCH_DATA_PATH)
	var saved_match_data = list_match_data()
	var list_size = list_match_data().size()
	if index < list_size and index + offset < list_size and index >= 0 and index + offset >= 0:
		var temp_name = "match_data_" + str(index + offset) + "_temp.tres"
		dir.rename(saved_match_data[index + offset], temp_name)
		dir.rename(saved_match_data[index], "match_data_" + str(index + offset) + ".tres")
		dir.rename(temp_name, "match_data_" + str(index) + ".tres")
