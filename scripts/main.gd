extends Control

signal player_data_updated
signal match_data_updated
signal selection_changed

@onready var file_menu = $VBoxContainer/MenuBar/File
@onready var help_menu = $VBoxContainer/MenuBar/Help

@onready var about_popup = $AboutPopup

@onready var players = $VBoxContainer/HSplitContainer/HSplitContainer/LeftTabContainer/Players
@onready var sessions = $VBoxContainer/HSplitContainer/HSplitContainer/CenterTabContainer/Sessions
@onready var editor = $VBoxContainer/HSplitContainer/HSplitContainer/CenterTabContainer/Editor
@onready var stats = $VBoxContainer/HSplitContainer/HSplitContainer/CenterTabContainer/Stats
@onready var properties = $VBoxContainer/HSplitContainer/RightTabContainer/Properties

@onready var center_tab_container = $VBoxContainer/HSplitContainer/HSplitContainer/CenterTabContainer
@onready var left_tab_container = $VBoxContainer/HSplitContainer/HSplitContainer/LeftTabContainer

@onready var export_file_dialog = $ExportFileDialog
@onready var import_file_dialog = $ImportFileDialog

func _init():
	Globals.setup_data_directories()

# Called when the node enters the scene tree for the first time.
func _ready():
	file_menu.connect("id_pressed", _on_file_menu_id_pressed)
	help_menu.connect("id_pressed", _on_help_menu_id_pressed)
	sessions.connect("session_opened", _on_sessions_session_opened)
	sessions.connect("item_selected", _on_sessions_item_selected)
	sessions.connect("session_deleted", _on_sessions_session_deleted)
	_connect_editor_signals(editor)
	players.connect("save", _on_players_save)
	players.connect("player_selected", _on_players_player_selected)
	connect("player_data_updated", players._on_player_data_updated)
	stats.connect("save", _on_stats_save)
	stats.connect("player_selected", _on_stats_player_selected)
	connect("player_data_updated", stats._on_player_data_updated)
	connect("match_data_updated", stats._on_match_data_updated)
	connect("selection_changed", properties._on_selection_changed)
	properties.connect("session_opened", _on_properties_session_opened)
	properties.connect("match_edit", _on_properties_match_edit)
#	center_tab_container.connect("tab_changed", _on_center_tab_container_tab_changed)
	
	export_file_dialog.connect("file_selected", _on_export_file_dialog_file_selected)
	import_file_dialog.connect("file_selected", _on_import_file_dialog_file_selected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_file_menu_id_pressed(id):
	match id:
		0:
			import_file_dialog.show()
		1:
			export_file_dialog.show()
		2:
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Globals.SESSION_DATA_PATH))
		4:
			get_tree().quit()

func _on_help_menu_id_pressed(id):
	match id:
		0:
			about_popup.show()

func _on_sessions_session_opened(session_name):
	open_session(session_name)

func _on_properties_session_opened(session_name):
	open_session(session_name)

func _on_properties_match_edit(index):
	if not editor.match_editor_is_open:
		editor.edit_match(index)

func _on_editor_back_pressed():
	center_tab_container.current_tab = 0

func _on_editor_match_data_saved():
	emit_signal("match_data_updated", editor)

func _on_players_save(player_data):
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if dir:
		ResourceSaver.save(player_data, Globals.SESSION_DATA_PATH + "player_data.tres")
	emit_signal("player_data_updated", players)

func _on_players_player_selected(ids):
	emit_signal("selection_changed", "player", ids)
	sessions.clear_selection()
	editor.clear_selection()
	stats.clear_selection()

func _on_sessions_item_selected(ids):
	emit_signal("selection_changed", "session", ids)
	players.clear_selection()
	stats.clear_selection()

func _on_sessions_session_deleted(session_name):
	if session_name == editor.session_name:
		clear_editor()

func _on_editor_item_selected(ids):
	emit_signal("selection_changed", "match", ids)
	sessions.clear_selection()
	players.clear_selection()
	stats.clear_selection()

func _on_stats_player_selected(ids):
	emit_signal("selection_changed", "player", ids)
	sessions.clear_selection()
	editor.clear_selection()
	players.clear_selection()

func _on_stats_save(player_data):
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if dir:
		ResourceSaver.save(player_data, Globals.SESSION_DATA_PATH + "player_data.tres")
	# Enable when Stats Panel changes require updating other panels
#	emit_signal("player_data_updated", stats)

#func _on_center_tab_container_tab_changed(tab):
#	if tab == 2:
#		left_tab_container.hide()
#	else:
#		left_tab_container.show()

func _on_export_file_dialog_file_selected(path):
	pack_data(path)

func _on_import_file_dialog_file_selected(path):
	extract_data(path)

func _connect_editor_signals(editor_node):
	editor_node.connect("back_pressed", _on_editor_back_pressed)
	editor_node.connect("match_data_saved", _on_editor_match_data_saved)
	editor_node.connect("item_selected", _on_editor_item_selected)
	connect("player_data_updated", editor_node._on_player_data_updated)

func instantiate_editor():
	var editor_node = Globals.session_scene.instantiate()
	center_tab_container.add_child(editor_node)
	_connect_editor_signals(editor_node)
	return editor_node

func open_session(session_name):
	Globals.switch_session(session_name)
	center_tab_container.remove_child(editor)
	editor.queue_free()
	editor = instantiate_editor()
	center_tab_container.move_child(editor, 1)
	center_tab_container.current_tab = 1

func clear_editor():
	Globals.clear_session()
	center_tab_container.remove_child(editor)
	editor.queue_free()
	editor = instantiate_editor()
	center_tab_container.move_child(editor, 1)

func load_as_text(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content

func save_as_text(path, content):
	var err
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		err = FileAccess.get_open_error()
		if err == 7:
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			file = FileAccess.open(path, FileAccess.WRITE)
			if not file:
				return FileAccess.get_open_error()
		else:
			return FileAccess.get_open_error()
	file.store_string(content.get_string_from_utf8())

func pack_data(path):
	var writer := ZIPPacker.new()
	var err := writer.open(path)
	if err != OK:
		return err
	writer.start_file("session_data/player_data.tres")
	var dir = DirAccess.open(Globals.PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	var player_data
	if dir.file_exists("player_data.tres"):
		player_data = load_as_text(Globals.PLAYER_DATA_PATH + "player_data.tres")
	else:
		player_data = load_as_text("res://resources/player_data/default_player_data.tres")
	writer.write_file(player_data.to_utf8_buffer())
	writer.close_file()
	
	for folder in Globals.list_session_folders():
		if Globals.session_data_exists(folder):
			writer.start_file("session_data/" + folder + "/session_data.tres")
			var session_data = load_as_text(Globals.SESSION_DATA_PATH + folder + "/session_data.tres")
			writer.write_file(session_data.to_utf8_buffer())
			writer.close_file()
			for file in Globals.list_match_data(folder):
				writer.start_file("session_data/" + folder + "/match_data/" + file)
				var match_data = load_as_text(Globals.SESSION_DATA_PATH + folder + "/match_data/" + file)
				writer.write_file(match_data.to_utf8_buffer())
	
	writer.close()
	return OK

func extract_data(path):
	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		return PackedByteArray()
	Globals.delete_all_sessions()
	for file in reader.get_files():
		if ("user://" + file).get_file():
			var res := reader.read_file(file)
			save_as_text("user://" + file, res)
	reader.close()
	refresh_panels()

func refresh_panels():
	sessions.refresh_session_cards()
	emit_signal("player_data_updated")
	emit_signal("match_data_updated")
