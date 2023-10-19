extends Control

signal session_opened
signal match_edit

var player_icon = preload("res://assets/icons/players.svg")
var session_icon = preload("res://assets/icons/folder.svg")
var match_icon = preload("res://assets/icons/list.svg")
var generic_icon = preload("res://assets/icons/list.svg")

var selection := []
var active_id = null

@onready var selection_icon = $VBoxContainer/SelectionBar/SelectionIcon
@onready var selection_label = $VBoxContainer/SelectionBar/SelectionLabel
@onready var attribute_item_list = $VBoxContainer/AttributesPanelContainer/AttributeItemList

@onready var context_action_container = $VBoxContainer/ContextActionContainer
@onready var player_action_container = $VBoxContainer/ContextActionContainer/PlayerActionContainer
@onready var session_action_container = $VBoxContainer/ContextActionContainer/SessionActionContainer
@onready var match_action_container = $VBoxContainer/ContextActionContainer/MatchActionContainer

@onready var player_copy_button = $VBoxContainer/ContextActionContainer/PlayerActionContainer/PlayerCopyButton
@onready var session_copy_button = $VBoxContainer/ContextActionContainer/SessionActionContainer/SessionCopyButton
@onready var session_open_button = $VBoxContainer/ContextActionContainer/SessionActionContainer/SessionOpenButton
@onready var match_copy_button = $VBoxContainer/ContextActionContainer/MatchActionContainer/MatchCopyButton
@onready var match_edit_button = $VBoxContainer/ContextActionContainer/MatchActionContainer/MatchEditButton

# Called when the node enters the scene tree for the first time.
func _ready():
	player_copy_button.connect("pressed", _on_player_copy_button_pressed)
	match_copy_button.connect("pressed", _on_match_copy_button_pressed)
	match_edit_button.connect("pressed", _on_match_edit_button_pressed)
	session_copy_button.connect("pressed", _on_session_copy_button_pressed)
	session_open_button.connect("pressed", _on_session_open_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_player_copy_button_pressed():
	copy_all_attributes()

func _on_match_copy_button_pressed():
	copy_all_attributes()

func _on_match_edit_button_pressed():
	if active_id != null:
		emit_signal("match_edit", active_id)

func _on_session_copy_button_pressed():
	copy_all_attributes()

func _on_session_open_button_pressed():
	if active_id != null:
		emit_signal("session_opened", active_id)

func _on_selection_changed(type: String, selection_ids):
	clear_properties()
	if selection_ids.size() == 1:
		set_context_action(type)
		active_id = selection_ids[0]
	else:
		set_context_action(null)
		active_id = null
	match type:
		"player":
			var player_data = load_player_data()
			set_selection_icon("player")
			if selection_ids.size() > 1:
				set_selection_name("Player - " + selection_ids.size() + " Selected")
			elif selection_ids.size() == 1:
				var id = selection_ids[0]
				set_selection_name(player_data.names[id])
				attribute_item_list.add_item("Score:", player_data.scores[id])
				if player_data.matches and typeof(player_data.matches[id]) == TYPE_DICTIONARY:
					attribute_item_list.add_item("Matches:", player_data.matches[id].total)
					attribute_item_list.add_item("Wins:", player_data.matches[id].wins)
					attribute_item_list.add_item("Losses:", player_data.matches[id].losses)
		"session":
			set_selection_icon("session")
			if selection_ids.size() > 1:
				set_selection_name("Session - " + selection_ids.size() + " Selected")
			elif selection_ids.size() == 1:
				var session_name = selection_ids[0]
				var session_data = Globals.load_session_data(session_name)
				if session_data:
					set_selection_name(session_data.display_name)
					var date = Time.get_datetime_string_from_datetime_dict(session_data.date, true).split(" ")[0]
					attribute_item_list.add_item("Date Created:", date)
		"match":
			set_selection_icon("match")
			if selection_ids.size() > 1:
				set_selection_name("Match - " + selection_ids.size() + " Selected")
			elif selection_ids.size() == 1:
				var match_index = selection_ids[0]
				var match_data = Globals.load_match_data(match_index)
				if match_data:
					set_selection_name("Match " + str(match_index + 1))
					attribute_item_list.add_item("Winning Team:", "")
					for i in match_data.winning_player_ids.size():
						var player_id = match_data.winning_player_ids[i]
						if player_id == "":
							player_id = "-"
						else:
							player_id += ":"
						attribute_item_list.add_item(player_id, match_data.winning_scores[i], 1)
					attribute_item_list.add_item("Losing Team:", "")
					for i in match_data.losing_player_ids.size():
						var player_id = match_data.losing_player_ids[i]
						if player_id == "":
							player_id = "-"
						else:
							player_id += ":"
						attribute_item_list.add_item(player_id, match_data.losing_scores[i], 1)
					if match_data.overrides.size() > 0:
						attribute_item_list.add_item("Overrides:", "")
						for override in match_data.overrides:
							attribute_item_list.add_item(override.player_id, override.score, 1)
					# Todo: Support multiline values
#					if match_data.comments != "":
#						attribute_item_list.add_item("Comments:", match_data.comments)
				else:
					set_selection_icon(null)
					match_action_container.hide()

func load_player_data():
	var dir = DirAccess.open(Globals.PLAYER_DATA_PATH)
	if not dir:
		dir = DirAccess.open(Globals.SESSION_DATA_PATH) # Todo: Rewrite for proper handling of missing directories
	var player_data : PlayerData
	if dir.file_exists("player_data.tres"):
		player_data = ResourceLoader.load(Globals.PLAYER_DATA_PATH + "player_data.tres")
	else:
		player_data = ResourceLoader.load("res://resources/player_data/default_player_data.tres")
	return player_data

func clear_properties():
	attribute_item_list.clear()
	set_selection_name("")
	set_selection_icon(null)

func clear():
	clear_properties()
	set_context_action(null)

func set_selection_icon(type):
	var icon
	match type:
		"player":
			icon = player_icon
		"session":
			icon = session_icon
		"match":
			icon = generic_icon
		"generic":
			icon = generic_icon
		null:
			icon = null
	selection_icon.texture = icon

func set_selection_name(selection_name):
	selection_label.text = selection_name

func get_selection_name() -> String:
	return selection_label.text

func set_context_action(type):
	for node in context_action_container.get_children():
		node.hide()
	match type:
		"player":
			player_action_container.show()
		"match":
			match_action_container.show()
		"session":
			session_action_container.show()

func copy_all_attributes():
	var clipboard := ""
	clipboard += get_selection_name() + ":"
	for item in attribute_item_list.get_items():
		clipboard += "\n"
		clipboard += "  ".repeat(item.get_indent())
		clipboard += item.get_key()
		clipboard += " "
		clipboard += item.get_value()
	DisplayServer.clipboard_set(clipboard)
