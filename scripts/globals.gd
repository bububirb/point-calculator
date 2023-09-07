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

func save_session_data():
	var session_data = SessionData.new()
	session_data.display_name = current_session_display_name
	session_data.date = Time.get_date_dict_from_system()
	var dir = DirAccess.open(CURRENT_SESSION_PATH)
	if not dir:
		DirAccess.open(SESSION_DATA_PATH).make_dir(current_session_name)
	ResourceSaver.save(session_data, CURRENT_SESSION_PATH + "session_data.tres")

func list_session_folders():
	var session_folders = []
	var dir = DirAccess.open(Globals.SESSION_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
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
