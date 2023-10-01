extends Node

const SESSION_DATA_PATH := "user://session_data/"
var CURRENT_SESSION_PATH := ""
var current_session_name := "session"
var current_session_display_name := "Session"

var session_scene = preload("res://scenes/session.tscn")

func load_session(session_name):
	current_session_name = session_name
	CURRENT_SESSION_PATH = SESSION_DATA_PATH + current_session_name + "/"
	get_tree().change_scene_to_packed(session_scene)

func create_session(session_name, session_display_name):
	current_session_name = session_name
	current_session_display_name = session_display_name
	CURRENT_SESSION_PATH = SESSION_DATA_PATH + current_session_name + "/"
	save_session_data()
	get_tree().change_scene_to_packed(session_scene)

func save_session_data(custom_data = null, custom_name = null):
	# custom_data requires a custom_name too
	var session_data
	var dir
	if not (custom_data and custom_name):
		session_data = SessionData.new()
		session_data.display_name = current_session_display_name
		var index = list_session_folders().size()
		if list_session_folders().has(current_session_name):
			index -= 1
		session_data.index = index
		session_data.date = Time.get_date_dict_from_system()
		dir = DirAccess.open(CURRENT_SESSION_PATH)
		if not dir:
			DirAccess.open(SESSION_DATA_PATH).make_dir(current_session_name)
		ResourceSaver.save(session_data, CURRENT_SESSION_PATH + "session_data.tres")
	elif custom_data and custom_name:
		var custom_session_path = SESSION_DATA_PATH + custom_name + "/"
		dir = DirAccess.open(custom_session_path)
		if not dir:
			DirAccess.open(SESSION_DATA_PATH).make_dir(custom_name)
		ResourceSaver.save(custom_data, custom_session_path + "session_data.tres")
	else:
		print("Custom Data and Custom Name must be specified together")

func list_session_folders():
	var session_folders = []
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if dir.file_exists(file_name + "/session_data.tres"):
					session_folders.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return session_folders

func load_session_data(session_name):
	var session_data = null
	var dir = DirAccess.open(SESSION_DATA_PATH + session_name + "/")
	if dir:
		if dir.file_exists("session_data.tres"):
			session_data = ResourceLoader.load(SESSION_DATA_PATH + session_name + "/session_data.tres")
	return session_data

func list_match_data(session_name):
	var saved_match_data = []
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH + session_name + "/match_data/")
	if dir:
		saved_match_data = dir.get_files()
	return saved_match_data

# Deprecated after switching to global player data
#func load_player_data(session_name):
#	var player_data = null
#	var dir = DirAccess.open(SESSION_DATA_PATH + session_name + "/player_data/")
#	if dir:
#		if dir.file_exists("player_data.tres"):
#			player_data = ResourceLoader.load(SESSION_DATA_PATH + session_name + "/player_data/player_data.tres")
#	return player_data

func delete_session(session_name):
	var dir = DirAccess.open(SESSION_DATA_PATH + session_name + "/")
	if dir:
		OS.move_to_trash(ProjectSettings.globalize_path(SESSION_DATA_PATH + session_name + "/"))

func move_session(session_name, offset):
	var sessions = list_session_folders()
	var indices = []
	for session in sessions:
		var session_data = load_session_data(session)
		if session_data:
			if session_data.index:
				indices.append(session_data.index)
			else:
				indices.append(0)
		else:
			indices.append(0)
	var current_session_data = load_session_data(session_name)
	var target_session_index = current_session_data.index + offset
	current_session_data.index += offset
	save_session_data(current_session_data, session_name)
	var target_session_data
	for i in sessions.size():
		if indices[i] == target_session_index:
			target_session_data = load_session_data(sessions[i])
			target_session_data.index -= offset
			save_session_data(target_session_data, sessions[i])

func list_ordered_session_folders():
	var session_folders = list_session_folders()
	session_folders.sort_custom(session_sort)
	return session_folders

func session_sort(a, b):
	var session_data_a = load_session_data(a) 
	var session_data_b = load_session_data(b)
	return session_data_a.index < session_data_b.index
