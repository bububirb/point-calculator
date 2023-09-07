extends Control

const SAVE_PATH = "user://match_data/"

@onready var main_container = $MainContainer
@onready var card_list = $MainContainer/CardList
@onready var editor = $MainContainer/Editor
@onready var new_button = $NewButton

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.get_name() == "Windows":
		connect("resized", new_button.update_x_position)
	elif OS.get_name() == "Android":
		resized.connect(_fit_display_cutouts)
		_fit_display_cutouts()
		card_list.connect("scrolling", _on_card_list_scrolling)
	
	new_button.connect("pressed", _on_new_button_pressed)
	
	card_list.connect("card_edit", _on_card_list_card_edit)
	card_list.connect("card_delete", _on_card_list_card_delete)
	editor.connect("cancel", _on_editor_cancel)
	editor.connect("save", _on_editor_save)
	
	load_match_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _fit_display_cutouts():
	main_container.set_position(DisplayServer.get_display_safe_area().position)
	main_container.set_size(DisplayServer.get_display_safe_area().size)
	new_button.update_x_position()

func _on_card_list_scrolling(scroll_offset):
	if scroll_offset == 0:
		new_button.expand_button()
	else:
		new_button.contract_button()

func _on_card_list_card_edit(index):
	open_editor()
	set_edit_index(index)
	editor.load_match_data()

func _on_card_list_card_delete(index):
	var saved_match_data = list_match_data()
	if saved_match_data:
		var dir = DirAccess.open(SAVE_PATH)
		dir.remove(SAVE_PATH + saved_match_data[index])
		reorder_match_data()

func open_editor():
	var editor_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	editor_tween.tween_property(editor, "size_flags_stretch_ratio", 1.0, 0.4)
	var card_list_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	card_list_tween.tween_property(card_list, "size_flags_stretch_ratio", 0.0, 0.4)
	new_button.hide_button()

func close_editor():
	var editor_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	editor_tween.tween_property(editor, "size_flags_stretch_ratio", 0.0, 0.4)
	var card_list_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	card_list_tween.tween_property(card_list, "size_flags_stretch_ratio", 1.0, 0.4)
	new_button.show_button()

func set_edit_index(index):
	editor.edit_index = index

func _on_editor_cancel():
	var dir = DirAccess.open(SAVE_PATH)
	if not dir.file_exists("match_data_" + str(editor.edit_index) + ".tres"):
		card_list.delete_card(editor.edit_index)
	close_editor()

func _on_editor_save(edit_index, winning_scores, losing_scores, quota, winning_weights, losing_weights):
	card_list.set_card_scores(edit_index, winning_scores, losing_scores)
	var match_data = MatchData.new()
	match_data.quota = quota
	match_data.winning_weights = winning_weights
	match_data.losing_weights = losing_weights
	match_data.winning_scores = winning_scores
	match_data.losing_scores = losing_scores
	var dir = DirAccess.open(SAVE_PATH)
	if not dir:
		DirAccess.open("user://").make_dir("match_data")
	ResourceSaver.save(match_data, SAVE_PATH + "match_data_" + str(edit_index) + ".tres")
	close_editor()

func list_match_data():
	var saved_match_data = []
	var dir = DirAccess.open(SAVE_PATH)
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

func load_match_data():
	for file in list_match_data():
		var match_data = ResourceLoader.load(SAVE_PATH + file)
		card_list.load_card(match_data)

func _on_new_button_pressed():
	card_list.add_card()

func reorder_match_data():
	var dir = DirAccess.open(SAVE_PATH)
	var saved_match_data = list_match_data()
	for i in saved_match_data.size():
		dir.rename(saved_match_data[i], "match_data_" + str(i) + ".tres")
