extends Control

signal tween_finished
signal back_pressed
signal match_data_saved
signal item_selected

var MATCH_DATA_PATH : String
var PLAYER_DATA_PATH : String

const TWEEN_DURATION = 0.3
const EDIT_BAR_WIDTH = 36.0

var session_name = ""
var match_editor_is_open := false

@onready var main_container = $MainContainer
@onready var edit_button = $MainContainer/MenuBar/HBoxContainer/EditButton
@onready var match_list = $MainContainer/MatchListContainer/HBoxContainer/MatchList
@onready var match_list_container = $MainContainer/MatchListContainer
@onready var edit_bar = $MainContainer/MatchListContainer/HBoxContainer/EditBar
@onready var match_editor = $MainContainer/MatchEditor
@onready var new_button = $MainContainer/MenuBar/HBoxContainer/NewButton
@onready var menu_bar = $MainContainer/MenuBar
@onready var back_button = $MainContainer/MenuBar/HBoxContainer/BackButton
@onready var session_name_label = $MainContainer/MenuBar/HBoxContainer/SessionNameLabel

@onready var blank_label = $MainContainer/MatchListContainer/HBoxContainer/MatchList/BlankLabel

@onready var move_up_button = $MainContainer/MatchListContainer/HBoxContainer/EditBar/MarginContainer/VBoxContainer/MoveUpButton
@onready var move_down_button = $MainContainer/MatchListContainer/HBoxContainer/EditBar/MarginContainer/VBoxContainer/MoveDownButton
@onready var delete_button = $MainContainer/MatchListContainer/HBoxContainer/EditBar/MarginContainer/VBoxContainer/DeleteButton

@onready var delete_confirmation_dialog = $DeleteConfirmationDialog

@onready var menu_bar_height = menu_bar.size.y

func _init():
	session_name = Globals.current_session_name
	var dir = DirAccess.open(Globals.CURRENT_SESSION_PATH)
	if not dir:
		DirAccess.open(Globals.SESSION_DATA_PATH).make_dir(session_name)
	MATCH_DATA_PATH = Globals.CURRENT_SESSION_PATH + "match_data/"
	PLAYER_DATA_PATH = Globals.SESSION_DATA_PATH #+ "player_data/" # Global player data refactor

func _ready():
	if Globals.CURRENT_SESSION_PATH == "":
		menu_bar.hide()
		blank_label.show()
	if OS.get_name() == "Windows":
		pass
	elif OS.get_name() == "Android":
		resized.connect(_fit_display_cutouts)
		_fit_display_cutouts()
	
	new_button.connect("pressed", _on_new_button_pressed)
	back_button.connect("pressed", _on_back_button_pressed)
	edit_button.connect("toggled", _on_edit_button_toggled)
	
	move_up_button.connect("pressed", _on_move_up_button_pressed)
	move_down_button.connect("pressed", _on_move_down_button_pressed)
	delete_button.connect("pressed", _on_delete_button_pressed)
	
	delete_confirmation_dialog.connect("confirmed", _on_delete_confirmation_dialog_confirmed)
	
	match_list.connect("entry_edit", _on_match_list_entry_edit)
	match_list.connect("entry_delete", _on_match_list_entry_delete)
	match_list.connect("entry_move_up", _on_match_list_entry_move_up)
	match_list.connect("entry_move_down", _on_match_list_entry_move_down)
	match_list.connect("entry_duplicate", _on_match_list_entry_duplicate)
	match_list.connect("item_selected", _on_match_list_item_selected)
	
	match_editor.connect("cancel", _on_match_editor_cancel)
	match_editor.connect("save", _on_match_editor_save)
	
	load_match_data()
	load_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _fit_display_cutouts():
	main_container.set_position(DisplayServer.get_display_safe_area().position)
	main_container.set_size(DisplayServer.get_display_safe_area().size)

func _on_player_data_updated(sender = null):
	if sender != self:
		match_editor.refresh_player_options()

func _on_match_list_entry_edit(index):
	edit_match(index)

func _on_match_list_entry_delete(index):
	var saved_match_data = list_match_data()
	if saved_match_data:
		OS.move_to_trash(ProjectSettings.globalize_path(MATCH_DATA_PATH + saved_match_data[index]))
		reorder_match_data()

func _on_match_list_entry_move_up(index):
	move_match_data(index, -1)

func _on_match_list_entry_move_down(index):
	move_match_data(index, 1)

func _on_match_list_entry_duplicate(index):
	var list = list_match_data()
	if index < list.size():
		var match_data = ResourceLoader.load(MATCH_DATA_PATH + list[index])
		save_match_data(match_data, list_match_data().size())
		match_list.load_entry(match_data)

func _on_match_list_item_selected(selection):
	emit_signal("item_selected", selection)

func set_edit_index(index):
	match_editor.edit_index = index

func _on_match_editor_cancel():
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir.file_exists("match_data_" + str(match_editor.edit_index) + ".tres"):
		match_list.delete_entry(match_editor.edit_index)
	close_match_editor()

func _on_match_editor_save(edit_index, match_data : MatchData):
	match_list.set_entry_scores(edit_index, match_data.winning_scores, match_data.losing_scores)
	save_match_data(match_data, edit_index)
	close_match_editor()

func edit_match(index):
	open_match_editor()
	match_list.select(index)
	# Deferred match editor loading
	await tween_finished
	set_edit_index(index)
	match_editor.load_match_data()
	match_editor.load_player_data()

func save_match_data(match_data, index):
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if not dir:
		DirAccess.open(Globals.CURRENT_SESSION_PATH).make_dir("match_data")
	ResourceSaver.save(match_data, MATCH_DATA_PATH + "match_data_" + str(index) + ".tres")
	emit_signal("match_data_saved")

func load_data():
	var session_data = Globals.load_session_data(session_name)
	if session_data:
		Globals.current_session_display_name = session_data.display_name
		session_name_label.text = session_data.display_name

func open_match_editor():
	match_editor_is_open = true
	match_editor.reset()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	tween.tween_property(match_editor, "size_flags_stretch_ratio", 1.0, TWEEN_DURATION)
	tween.tween_property(match_list_container, "size_flags_stretch_ratio", 0.0, TWEEN_DURATION)
	tween.tween_property(menu_bar, "custom_minimum_size:y", 0.0, TWEEN_DURATION)
	new_button.disabled = true
	# For deferred match editor loading
	await tween.finished
	emit_signal("tween_finished")

func close_match_editor():
	match_editor_is_open = false
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	tween.tween_property(match_editor, "size_flags_stretch_ratio", 0.0, TWEEN_DURATION)
	tween.tween_property(match_list_container, "size_flags_stretch_ratio", 1.0, TWEEN_DURATION)
	tween.tween_property(menu_bar, "custom_minimum_size:y", menu_bar_height, TWEEN_DURATION)
	new_button.disabled = false

func list_match_data():
	var saved_match_data = []
	var dir = DirAccess.open(MATCH_DATA_PATH)
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

func load_match_data():
	for file in list_match_data():
		var match_data = ResourceLoader.load(MATCH_DATA_PATH + file)
		match_list.load_entry(match_data)

func _on_new_button_pressed():
	match_list.add_entry()
	new_button.disabled = true

func _on_back_button_pressed():
	emit_signal("back_pressed")

func _on_edit_button_toggled(button_pressed):
	var new_width = float(button_pressed) * EDIT_BAR_WIDTH
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(edit_bar, "custom_minimum_size:x", new_width, TWEEN_DURATION * 0.2)

func _on_move_up_button_pressed():
	match_list.move_selected_entries_up()

func _on_move_down_button_pressed():
	match_list.move_selected_entries_down()

func _on_delete_button_pressed():
	delete_confirmation_dialog.show()

func _on_delete_confirmation_dialog_confirmed():
	match_list.delete_selected_entries()

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

func clear_selection():
	match_list.clear_selection()
