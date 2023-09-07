extends Control

var session_card_scene = preload("res://scenes/session_card.tscn")

var tween_duration = 0.4

@onready var session_cards = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/SessionCardsPanel/VBoxContainer/ScrollContainer/SessionCards
@onready var session_name_input = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/SessionNameInput
@onready var session_name_preview_label = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/SessionNamePreviewLabel
@onready var new_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/NewButton
@onready var open_button = $Margin/VBoxContainer/SessionOptions/SessionOptionsContainer/PanelContainer/VBoxContainer/HBoxContainer/OpenButton
@onready var players_button = $Margin/VBoxContainer/TitleBar/TitleBarContainer/PlayersButton

# For player list integration
@onready var session_options = $Margin/VBoxContainer/SessionOptions
@onready var global_player_list = $Margin/VBoxContainer/GlobalPlayerList
@onready var title_bar = $Margin/VBoxContainer/TitleBar
@onready var menu_bar_height = title_bar.size.y


# Called when the node enters the scene tree for the first time.
func _ready():
	#print(hash(Time.get_unix_time_from_system()))
	session_name_input.connect("text_changed", _on_session_name_input_text_changed)
	session_name_input.connect("text_submitted", _on_session_name_input_text_submitted)
	new_button.connect("pressed", _on_new_button_pressed)
	open_button.connect("pressed", _on_open_button_pressed)
	players_button.connect("pressed", _on_players_button_pressed)
	global_player_list.connect("cancel", _on_player_list_cancel)
	global_player_list.connect("save", _on_player_list_save)
	make_session_data_dir()
	load_session_cards()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func delete_session(session_name):
	Globals.delete_session(session_name)

func make_session_data_dir():
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if not dir:
		DirAccess.open("user://").make_dir("session_data")

func load_session_cards():
	for session_folder in Globals.list_session_folders():
		var session_data = Globals.load_session_data(session_folder)
		# Waiting for local player data
#		var player_data = Globals.load_player_data(session_folder)
		
#		var player_count = 0
#		if player_data:
#			player_count = player_data.names.keys().size()
		
		var session_display_name = session_data.display_name
		
		var session_card_instance = session_card_scene.instantiate()
		session_cards.add_child(session_card_instance)
		session_card_instance.set_session_name(session_folder, session_display_name)
		session_card_instance.set_session_date(session_data.date)
		# Waiting for local player data
#		session_card_instance.set_player_count(player_count)
		session_card_instance.connect("open_pressed", _on_session_card_open_pressed)
		session_card_instance.connect("delete_pressed", _on_session_card_delete_pressed)

func _on_session_card_open_pressed(session_name):
	Globals.load_session(session_name)

func _on_session_card_delete_pressed(session_name):
	delete_session(session_name)

func _on_session_name_input_text_changed(new_text : String):
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() or new_text == "":
		if Globals.list_session_folders().has(new_text):
			switch_to_open()
		else:
			switch_to_new()
		session_name_preview_label.text = new_text
	else:
		session_name_preview_label.text = "Not a valid name"

func _on_session_name_input_text_submitted(new_text : String):
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() and new_text != "":
		if Globals.list_session_folders().has(new_text):
			Globals.load_session(new_text)
		else:
			Globals.create_session(new_text, session_name_input.text)

func _on_new_button_pressed():
	var new_text = session_name_input.text
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() and new_text != "":
		Globals.create_session(new_text, session_name_input.text)

func _on_open_button_pressed():
	var new_text = session_name_input.text
	new_text = new_text.strip_edges().to_snake_case()
	if new_text.is_valid_filename() and new_text != "":
		Globals.load_session(new_text)

func _on_players_button_pressed():
	open_player_list()
	players_button.disabled = true

func _on_player_list_cancel():
	close_player_list()

func _on_player_list_save(names, scores):
	var player_data = PlayerData.new()
	player_data.names = names
	player_data.scores = scores
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if dir:
		ResourceSaver.save(player_data, Globals.SESSION_DATA_PATH + "player_data.tres")
	close_player_list()

func switch_to_open():
	if new_button.visible:
		new_button.hide()
		open_button.show()

func switch_to_new():
	if open_button.visible:
		open_button.hide()
		new_button.show()

# For player list integration
func open_player_list():
	global_player_list.load_player_item_list()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(global_player_list, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(session_options, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(title_bar, "custom_minimum_size:y", 0.0, tween_duration)
	players_button.disabled = true

func close_player_list():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(global_player_list, "size_flags_stretch_ratio", 0.0, tween_duration)
	tween.tween_property(session_options, "size_flags_stretch_ratio", 1.0, tween_duration)
	tween.tween_property(title_bar, "custom_minimum_size:y", menu_bar_height, tween_duration)
	players_button.disabled = false
