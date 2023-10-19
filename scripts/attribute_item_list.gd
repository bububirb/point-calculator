extends Control

signal item_selected
signal sorted

var attribute_entry_scene : PackedScene = load("res://scenes/attribute_entry.tscn")

var sort_type = "player_name"
var reversed = false

var selection = []
var item_count = 0
var player_entries_order = []

@onready var attribute_entry_container = $ScrollContainer/AttributeEntryContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	instantiate_player_entry(null, null, null)
#	instantiate_player_entry(null, null, null)
#	instantiate_player_entry(null, null, null)
#	instantiate_player_entry(null, null, null)
#	instantiate_player_entry(null, null, null)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func instantiate_attribute_entry(key, value, indent):
	var attribute_entry_node = attribute_entry_scene.instantiate()
	attribute_entry_container.add_child(attribute_entry_node)
	attribute_entry_node.connect("selected", _on_attribute_entry_selected)
	attribute_entry_node.set_key(key)
	attribute_entry_node.set_value(value)
	attribute_entry_node.set_indent(indent)

func _on_attribute_entry_selected(index):
	select(index)

#func _on_sort_button_pressed(type):
#	if type == sort_type:
#		reversed = !reversed
#	else:
#		sort_type = type
#		reversed = false
#	switch_sort_arrow(sort_type, reversed)
#	sort_player_entries()

#func switch_sort_arrow(type, is_reversed):
#	var player_name_arrow = player_name_sort_button.get_node("Arrow")
#	var local_score_arrow = local_score_sort_button.get_node("Arrow")
#	var global_score_arrow = global_score_sort_button.get_node("Arrow")
#	var matches_arrow = matches_sort_button.get_node("Arrow")
#	player_name_arrow.visible = type == "player_name"
#	local_score_arrow.visible = type == "local_score"
#	global_score_arrow.visible = type == "global_score"
#	matches_arrow.visible = type == "matches"
#	player_name_arrow.flip_v = is_reversed
#	local_score_arrow.flip_v = is_reversed
#	global_score_arrow.flip_v = is_reversed
#	matches_arrow.flip_v = is_reversed

#func sort_player_entries():
#	var sorted_nodes = player_entry_container.get_children()
#	sorted_nodes.sort_custom(sort_function)
#	for player_entry in player_entry_container.get_children():
#		player_entry_container.remove_child(player_entry)
#	for node in sorted_nodes:
#		player_entry_container.add_child(node)
#	update_selection()
#	emit_signal("sorted")

#func sort_function(a, b):
#	var value_a
#	var value_b
#	match sort_type:
#		"player_name":
#			value_a = a.get_player_name()
#			value_b = b.get_player_name()
#			if not reversed:
#				return value_a.naturalnocasecmp_to(value_b) < 0
#			else:
#				return value_a.naturalnocasecmp_to(value_b) > 0
#		"local_score":
#			value_a = a.get_local_score()
#			value_b = b.get_local_score()
#			if not reversed:
#				return value_a > value_b
#			else:
#				return value_a < value_b
#		"global_score":
#			value_a = a.get_global_score()
#			value_b = b.get_global_score()
#			if not reversed:
#				return value_a > value_b
#			else:
#				return value_a < value_b
#		"matches":
#			value_a = a.get_matches()
#			value_b = b.get_matches()
#			if not reversed:
#				return value_a > value_b
#			else:
#				return value_a < value_b

func add_item(key, value, indent = 0):
	instantiate_attribute_entry(key, value, indent)
	update_item_count()
#	sort_player_entries()

func remove_item(index):
	attribute_entry_container.get_child(index).free()
	selection.erase(index)
	update_item_count()

func clear():
	for attribute_entry in attribute_entry_container.get_children():
		attribute_entry.free()
	update_item_count()
	update_selection()

func select(index, clear_existing = true):
	if clear_existing:
		for attribute_entry in attribute_entry_container.get_children():
			attribute_entry.deselect()
	attribute_entry_container.get_child(index).select()
	update_selection()
	update_selection_draw()
	emit_signal("item_selected", index)

func get_selected_items():
	return selection

func set_indent(index, value):
	attribute_entry_container.get_child(index).set_indent(value)

func set_key(index, key):
	attribute_entry_container.get_child(index).set_key(key)

func set_value(index, value):
	attribute_entry_container.get_child(index).set_value(value)

func get_indent(index):
	return attribute_entry_container.get_child(index).get_indent()

func get_key(index):
	return attribute_entry_container.get_child(index).get_key()

func get_value(index):
	return attribute_entry_container.get_child(index).get_value()

func get_items():
	return attribute_entry_container.get_children()

func get_item_count():
	update_item_count()
	return item_count

func update_item_count():
	item_count = attribute_entry_container.get_child_count()

func update_selection():
	selection.clear()
	for attribute_entry in attribute_entry_container.get_children():
		if attribute_entry.is_selected:
			selection.append(attribute_entry.get_index())

func update_selection_draw():
	for attribute_entry in attribute_entry_container.get_children():
		if attribute_entry.is_selected:
			attribute_entry.draw_selection()
		else:
			attribute_entry.draw_selection(false)
