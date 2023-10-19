extends Control

signal session_opened
signal session_deleted
signal item_selected

var session_card_scene = preload("res://scenes/session_entry.tscn")

const TWEEN_DURATION = 0.4
const ERROR_COLOR = Color(1.0, 0.5, 0.5)
const EDIT_BAR_WIDTH = 36.0

var selection = []

@onready var session_cards = %SessionCards
@onready var session_name_input = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/SessionNameInput
@onready var session_name_preview_label = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/SessionNamePreviewLabel
@onready var new_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/NewButton
@onready var open_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/OpenButton

@onready var edit_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/HBoxContainer3/EditButton
@onready var edit_bar = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/SessionCardsPanel/HBoxContainer/EditBar
@onready var move_up_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/SessionCardsPanel/HBoxContainer/EditBar/MarginContainer/VBoxContainer/MoveUpButton
@onready var move_down_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/SessionCardsPanel/HBoxContainer/EditBar/MarginContainer/VBoxContainer/MoveDownButton
@onready var delete_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/SessionCardsPanel/HBoxContainer/EditBar/MarginContainer/VBoxContainer/DeleteButton
@onready var delete_confirmation_dialog = $DeleteConfirmationDialog

@onready var session_options = $Margin/VBoxContainer/SessionOptions


# Called when the node enters the scene tree for the first time.
func _ready():
	#print(hash(Time.get_unix_time_from_system()))
	session_name_input.connect("text_changed", _on_session_name_input_text_changed)
	session_name_input.connect("text_submitted", _on_session_name_input_text_submitted)
	new_button.connect("pressed", _on_new_button_pressed)
	open_button.connect("pressed", _on_open_button_pressed)
#	players_button.connect("pressed", _on_players_button_pressed)
#	show_button.connect("pressed", _on_show_button_pressed)
	edit_button.connect("toggled", _on_edit_button_toggled)
	move_up_button.connect("pressed", _on_move_up_button_pressed)
	move_down_button.connect("pressed", _on_move_down_button_pressed)
	delete_button.connect("pressed", _on_delete_button_pressed)
	delete_confirmation_dialog.connect("confirmed", _on_delete_confirmation_dialog_confirmed)
	make_session_data_dir()
	load_session_cards()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func delete_session(session_name):
	Globals.delete_session(session_name)

func move_session(session_name, index, offset):
	var list_size = session_cards.get_child_count()
	if index < list_size and index + offset < list_size and index >= 0 and index + offset >= 0:
		Globals.move_session(session_name, offset)
		session_cards.get_child(index).set_session_index(index + offset)
		session_cards.get_child(index + offset).set_session_index(index)
		sort_session_cards()

func make_session_data_dir():
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if not dir:
		DirAccess.open("user://").make_dir("session_data")

func load_session_cards():
	for session_folder in Globals.list_session_folders():
		var session_data = Globals.load_session_data(session_folder)
		var session_display_name = session_data.display_name
		
		var session_card_instance = session_card_scene.instantiate()
		session_cards.add_child(session_card_instance)
		session_card_instance.set_session_name(session_folder, session_display_name)
		session_card_instance.set_session_index(session_data.index)
		session_card_instance.set_session_date(session_data.date)
		
		sort_session_cards()
		session_card_instance.connect("open_pressed", _on_session_card_open_pressed)
		session_card_instance.connect("delete_pressed", _on_session_card_delete_pressed)
		session_card_instance.connect("moved_up", _on_session_card_moved_up)
		session_card_instance.connect("moved_down", _on_session_card_moved_down)
		session_card_instance.connect("selected", _on_session_card_selected)

func clear_session_cards():
	for session_card in session_cards.get_children():
		session_card.free()

func refresh_session_cards():
	clear_session_cards()
	load_session_cards()

func _on_session_card_open_pressed(session_name):
	emit_signal("session_opened", session_name)

func _on_session_card_delete_pressed(session_name):
	delete_session(session_name)

func _on_session_card_moved_up(session_name, index):
	move_session(session_name, index, -1)

func _on_session_card_moved_down(session_name, index):
	move_session(session_name, index, 1)

func _on_session_card_selected(index):
	select(index)

func _on_move_up_button_pressed():
	var index
	var session_name
	if selection.size() == 1:
		session_name = selection[0]
		index = get_session_index(session_name)
		move_session(session_name, index, -1)

func _on_move_down_button_pressed():
	var index
	var session_name
	if selection.size() == 1:
		session_name = selection[0]
		index = get_session_index(session_name)
		move_session(session_name, index, 1)

func _on_delete_button_pressed():
	if selection.size() > 0:
		delete_confirmation_dialog.show()

func _on_delete_confirmation_dialog_confirmed():
	for session_name in selection:
		delete_session(session_name)
		var index = get_session_index(session_name)
		session_cards.get_child(index).queue_free()
		emit_signal("session_deleted", session_name)
	emit_signal("item_selected", selection)

func _on_session_name_input_text_changed(new_text : String):
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() or new_text == "":
		if Globals.list_session_folders().has(new_text):
			switch_to_open()
		else:
			switch_to_new()
		session_name_preview_label.text = new_text
		session_name_preview_label.self_modulate = Color.WHITE
	else:
		session_name_preview_label.text = "Not a valid name"
		session_name_preview_label.self_modulate = ERROR_COLOR

func _on_session_name_input_text_submitted(new_text : String):
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() and new_text != "":
		if Globals.list_session_folders().has(new_text):
			emit_signal("session_opened", new_text)
		else:
			Globals.create_session(new_text, session_name_input.text)
			emit_signal("session_opened", new_text)
		refresh_session_cards()
		clear_session_name_input()

func _on_new_button_pressed():
	var new_text = session_name_input.text
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() and new_text != "":
		Globals.create_session(new_text, session_name_input.text)
		emit_signal("session_opened", new_text)
		clear_session_name_input()
	elif new_text == "":
		session_name_preview_label.text = "Enter a session name"
		session_name_preview_label.self_modulate = ERROR_COLOR

func _on_open_button_pressed():
	var new_text = session_name_input.text
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() and new_text != "":
		emit_signal("session_opened", new_text)

func _on_show_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Globals.SESSION_DATA_PATH))

func _on_edit_button_toggled(button_pressed):
	var new_width = float(button_pressed) * EDIT_BAR_WIDTH
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(edit_bar, "custom_minimum_size:x", new_width, TWEEN_DURATION * 0.2)

func switch_to_open():
	if new_button.visible:
		new_button.hide()
		open_button.show()

func switch_to_new():
	if open_button.visible:
		open_button.hide()
		new_button.show()

func clear_session_name_input():
	session_name_input.text = ""
	session_name_preview_label.text = ""

func sort_session_cards():
	var sorted_nodes = session_cards.get_children()
	sorted_nodes.sort_custom(sort_function)
	for session_card in session_cards.get_children():
		session_cards.remove_child(session_card)
	for node in sorted_nodes:
		session_cards.add_child(node)

func sort_function(a, b):
	return a.get_session_index() < b.get_session_index()

func select(index, clear_existing = true):
	if clear_existing:
		for session_entry in session_cards.get_children():
			session_entry.deselect()
	session_cards.get_child(index).select()
	update_selection()
	update_selection_draw()
	emit_signal("item_selected", selection)

func clear_selection():
	for session_entry in session_cards.get_children():
		session_entry.deselect()
	update_selection()
	update_selection_draw()

func update_selection():
	selection.clear()
	for session_entry in session_cards.get_children():
		if session_entry.is_selected:
			selection.append(session_entry.session_name)

func update_selection_draw():
	for session_entry in session_cards.get_children():
		if session_entry.is_selected:
			session_entry.draw_selection()
		else:
			session_entry.draw_selection(false)

func get_session_index(session_name):
	var index = null
	for session_entry in session_cards.get_children():
		if session_entry.session_name == session_name:
			index = session_entry.get_index()
			return index
