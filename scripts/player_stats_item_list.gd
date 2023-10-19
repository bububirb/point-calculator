extends PanelContainer

signal item_selected
signal sorted

@export var show_local_scores = false
@export var show_global_scores = true
@export var show_matches = true
@export var show_wins = true
@export var show_losses = true

var player_entry_scene : PackedScene = load("res://scenes/player_stats_entry.tscn")

var sort_type = "player_name"
var reversed = false

var selection = []
var item_count = 0
var player_entries_order = []

@onready var player_entry_container = $VBoxContainer/ScrollContainer/PlayerEntryContainer

@onready var labels = $VBoxContainer/Panel/Labels
@onready var player_name_sort_button = $VBoxContainer/Panel/Labels/PlayerNameSortButton
@onready var local_score_sort_button = $VBoxContainer/Panel/Labels/LocalScoreSortButton
@onready var global_score_sort_button = $VBoxContainer/Panel/Labels/GlobalScoreSortButton
@onready var matches_sort_button = $VBoxContainer/Panel/Labels/MatchesSortButton
@onready var wins_sort_button = $VBoxContainer/Panel/Labels/WinsSortButton
@onready var losses_sort_button = $VBoxContainer/Panel/Labels/LossesSortButton

# Called when the node enters the scene tree for the first time.
func _ready():
	local_score_sort_button.visible = show_local_scores
	global_score_sort_button.visible = show_global_scores
	matches_sort_button.visible = show_matches
	wins_sort_button.visible = show_wins
	losses_sort_button.visible = show_losses

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func instantiate_player_entry(player_name, local_score, global_score, matches = null):
	var player_entry_node = player_entry_scene.instantiate()
	player_entry_container.add_child(player_entry_node)
	player_entry_node.connect("selected", _on_player_entry_selected)
	player_entry_node.set_player_name(player_name)
	if show_local_scores:
		player_entry_node.set_local_score(local_score)
	player_entry_node.show_local_score(show_local_scores)
	if show_global_scores:
		player_entry_node.set_global_score(global_score)
	player_entry_node.show_global_score(show_global_scores)
	var total = 0
	var wins = 0
	var losses = 0
	if typeof(matches) == TYPE_DICTIONARY:
		total = matches.total
		wins = matches.wins
		losses = matches.losses
	if show_matches:
		player_entry_node.set_matches(total)
	player_entry_node.show_matches(show_matches)
	if show_wins:
		player_entry_node.set_wins(wins)
	player_entry_node.show_wins(show_wins)
	if show_losses:
		player_entry_node.set_losses(losses)
	player_entry_node.show_losses(show_losses)

func _on_player_entry_selected(index):
	select(index)

func _on_sort_button_pressed(type):
	if type == sort_type:
		reversed = !reversed
	else:
		sort_type = type
		reversed = false
	switch_sort_arrow(sort_type, reversed)
	sort_player_entries()

func switch_sort_arrow(type, is_reversed):
	var player_name_arrow = player_name_sort_button.get_node("Arrow")
	var local_score_arrow = local_score_sort_button.get_node("Arrow")
	var global_score_arrow = global_score_sort_button.get_node("Arrow")
	var matches_arrow = matches_sort_button.get_node("Arrow")
	var wins_arrow = wins_sort_button.get_node("Arrow")
	var losses_arrow = losses_sort_button.get_node("Arrow")
	player_name_arrow.visible = type == "player_name"
	local_score_arrow.visible = type == "local_score"
	global_score_arrow.visible = type == "global_score"
	matches_arrow.visible = type == "matches"
	wins_arrow.visible = type == "wins"
	losses_arrow.visible = type == "losses"
	
	for node in labels.get_children():
		var arrow = node.get_node("Arrow")
		arrow.flip_v = is_reversed

func get_player_entries():
	return player_entry_container.get_children()

func get_sorted_player_entries():
	var sorted_nodes = get_player_entries()
	sorted_nodes.sort_custom(sort_function)
	return sorted_nodes

func sort_player_entries():
	var sorted_nodes = get_sorted_player_entries()
	for player_entry in get_player_entries():
		player_entry_container.remove_child(player_entry)
	for node in sorted_nodes:
		player_entry_container.add_child(node)
	update_selection()
	emit_signal("sorted")

func sort_function(a, b):
	var value_a
	var value_b
	match sort_type:
		"player_name":
			value_a = a.get_player_name()
			value_b = b.get_player_name()
			if not reversed:
				return value_a.naturalnocasecmp_to(value_b) < 0
			else:
				return value_a.naturalnocasecmp_to(value_b) > 0
		"local_score":
			value_a = a.get_local_score()
			value_b = b.get_local_score()
			if not reversed:
				return value_a > value_b
			else:
				return value_a < value_b
		"global_score":
			value_a = a.get_global_score()
			value_b = b.get_global_score()
			if not reversed:
				return value_a > value_b
			else:
				return value_a < value_b
		"matches":
			value_a = a.get_matches()
			value_b = b.get_matches()
			if not reversed:
				return value_a > value_b
			else:
				return value_a < value_b
		"wins":
			value_a = a.get_wins()
			value_b = b.get_wins()
			if not reversed:
				return value_a > value_b
			else:
				return value_a < value_b
		"losses":
			value_a = a.get_losses()
			value_b = b.get_losses()
			if not reversed:
				return value_a > value_b
			else:
				return value_a < value_b

func filter_options(filter_text):
	for player_entry in get_player_entries():
		var filter = "*" + filter_text.replace(" ", "*") + "*"
		player_entry.visible = player_entry.get_player_name().matchn(filter) or filter_text == ""

func add_item(player_name, local_score = 0, global_score = 0, matches = null):
	instantiate_player_entry(player_name, local_score, global_score, matches)
	update_item_count()
	sort_player_entries()

func remove_item(index):
	player_entry_container.get_child(index).free()
	selection.erase(index)
	update_item_count()

func clear():
	for player_entry in get_player_entries():
		player_entry.free()
	update_item_count()
	update_selection()

func select(index, clear_existing = true):
	if clear_existing:
		for player_entry in get_player_entries():
			player_entry.deselect()
	player_entry_container.get_child(index).select()
	update_selection()
	update_selection_draw()
	emit_signal("item_selected", index)

func clear_selection():
	for player_entry in get_player_entries():
		player_entry.deselect()
	update_selection()
	update_selection_draw()

func get_selected_items():
	return selection

func set_player_name(index, player_name):
	player_entry_container.get_child(index).set_player_name(player_name)

func set_local_score(index, local_score):
	player_entry_container.get_child(index).set_local_score(local_score)

func set_global_score(index, global_score):
	player_entry_container.get_child(index).set_global_score(global_score)

func set_matches(index, matches):
	player_entry_container.get_child(index).set_matches(matches)

func set_wins(index, wins):
	player_entry_container.get_child(index).set_wins(wins)

func set_losses(index, losses):
	player_entry_container.get_child(index).set_losses(losses)

func get_player_name(index):
	return player_entry_container.get_child(index).get_player_name()

func get_local_score(index):
	return player_entry_container.get_child(index).get_local_score()

func get_global_score(index):
	return player_entry_container.get_child(index).get_global_score()

func get_matches(index):
	return player_entry_container.get_child(index).get_matches()

func get_wins(index):
	return player_entry_container.get_child(index).get_wins()

func get_losses(index):
	return player_entry_container.get_child(index).get_losses()

func update_item_count():
	item_count = player_entry_container.get_child_count()

func update_selection():
	selection.clear()
	for player_entry in get_player_entries():
		if player_entry.is_selected:
			selection.append(player_entry.get_index())

func update_selection_draw():
	for player_entry in get_player_entries():
		if player_entry.is_selected:
			player_entry.draw_selection()
		else:
			player_entry.draw_selection(false)
