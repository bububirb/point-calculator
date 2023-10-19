extends PanelContainer

signal item_selected
signal sorted

var player_entry_scene : PackedScene = load("res://scenes/player_entry.tscn")

var sort_type = "player_name"
var reversed = false

var selection = []
var item_count = 0
var player_entries_order = []

@onready var player_entry_container = $VBoxContainer/ScrollContainer/PlayerEntryContainer

@onready var labels = $VBoxContainer/Panel/Labels
@onready var player_name_sort_button = $VBoxContainer/Panel/Labels/PlayerNameSortButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func instantiate_player_entry(player_name, pinned = false):
	var player_entry_node = player_entry_scene.instantiate()
	player_entry_container.add_child(player_entry_node)
	player_entry_node.connect("selected", _on_player_entry_selected)
	player_entry_node.set_player_name(player_name)
	if typeof(pinned) == TYPE_BOOL:
		player_entry_node.set_pinned(pinned)

func _on_player_entry_selected(index):
	select(index)

func _on_sort_button_pressed(type):
	if type == sort_type:
		reversed = !reversed
	else:
		sort_type = type
		reversed = false
	sort_player_entries()

func switch_sort_arrow(type, is_reversed):
	var player_name_arrow = player_name_sort_button.get_node("Arrow")
	player_name_arrow.visible = type == "player_name"
	
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
	switch_sort_arrow(sort_type, reversed)
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
	var pinned_a = int(a.get_pinned())
	var pinned_b = int(b.get_pinned())
	var pinned_cmp = pinned_a - pinned_b
	match sort_type:
		"player_name":
			value_a = a.get_player_name()
			value_b = b.get_player_name()
			if not reversed:
				return value_a.naturalnocasecmp_to(value_b) - pinned_cmp * 2 < 0
			else:
				return value_a.naturalnocasecmp_to(value_b) + pinned_cmp * 2 > 0

func toggle_reverse():
	reversed = !reversed
	sort_player_entries()

func filter_options(filter_text):
	for player_entry in get_player_entries():
		var filter = "*" + filter_text.replace(" ", "*") + "*"
		player_entry.visible = player_entry.get_player_name().matchn(filter) or filter_text == ""

func add_item(player_name, pinned = false):
	instantiate_player_entry(player_name, pinned)
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

func set_pinned(index, pinned):
	player_entry_container.get_child(index).set_pinned(pinned)

func get_player_name(index):
	return player_entry_container.get_child(index).get_player_name()

func get_pinned(index):
	return player_entry_container.get_child(index).get_pinned()

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
