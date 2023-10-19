extends Control

signal scrolling
signal entry_edit
signal entry_delete
signal entry_move_up
signal entry_move_down
signal entry_duplicate
signal item_selected

var scroll_offset = 0.0
var scroll_direction = 0

var selection = []

#@export var column_min_size = 512
#@export var columns_max = 2

@onready var scroll_container = $ScrollContainer
@onready var entry_container = $ScrollContainer/EntryContainer

var match_entry_scene = load("res://scenes/match_entry.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
#	connect("resized", _on_resized)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (scroll_offset == 0) != (scroll_container.scroll_vertical == 0):
		emit_scroll_signal()
	scroll_offset = scroll_container.scroll_vertical

func emit_scroll_signal():
	emit_signal("scrolling", scroll_container.scroll_vertical)

#func _on_resized():
#	# Dynamic columns
#	entry_container.columns = clampi(floori(size.x / column_min_size), 1, columns_max)

func _on_entry_edit_pressed(index):
	emit_signal("entry_edit", index)

func _on_entry_delete_pressed(index):
	emit_signal("entry_delete", index)

func _on_entry_duplicate_pressed(index):
	emit_signal("entry_duplicate", index)

func _on_entry_selected(index):
	select(index)

func _on_entry_move_up_pressed(index):
	move_entry_up(index)

func _on_entry_move_down_pressed(index):
	move_entry_down(index)

func load_entry(match_data):
	var match_entry = match_entry_scene.instantiate()
	entry_container.add_child(match_entry)
	match_entry.set_scores(match_data.winning_scores, match_data.losing_scores)
	match_entry.connect("entry_edit_pressed", _on_entry_edit_pressed)
	match_entry.connect("entry_duplicate_pressed", _on_entry_duplicate_pressed)
	match_entry.connect("selected", _on_entry_selected)


func add_entry():
	var match_entry = match_entry_scene.instantiate()
	entry_container.add_child(match_entry)
	emit_signal("entry_edit", entry_container.get_child_count() - 1)
	match_entry.connect("entry_edit_pressed", _on_entry_edit_pressed)
	match_entry.connect("entry_duplicate_pressed", _on_entry_duplicate_pressed)
	match_entry.connect("selected", _on_entry_selected)

func move_selected_entries_up():
	for index in selection:
		move_entry_up(index)
	update_selection()
	emit_signal("item_selected", selection)

func move_selected_entries_down():
	var selection_reversed = selection.duplicate()
	selection_reversed.reverse()
	for index in selection_reversed:
		move_entry_down(index)
	update_selection()
	emit_signal("item_selected", selection)

func delete_selected_entries():
	var selection_reversed = selection.duplicate()
	selection_reversed.reverse()
	for index in selection_reversed:
		delete_entry(index)
		emit_signal("entry_delete", index)
	update_selection()
	emit_signal("item_selected", selection)

func move_entry_up(index):
	var new_index = clamp(index - 1, 0, entry_container.get_child_count() - 1)
	entry_container.move_child(entry_container.get_child(index), new_index)
	entry_container.get_child(index).update_index()
	entry_container.get_child(new_index).update_index()
	emit_signal("entry_move_up", index)
	update_indices()

func move_entry_down(index):
	var new_index = clamp(index + 1, 0, entry_container.get_child_count() - 1)
	entry_container.move_child(entry_container.get_child(index), new_index)
	entry_container.get_child(index).update_index()
	entry_container.get_child(new_index).update_index()
	emit_signal("entry_move_down", index)
	update_indices()

func delete_entry(index):
	entry_container.get_child(index).free()
	update_indices()

func set_entry_scores(index, winning_scores, losing_scores):
	entry_container.get_child(index).set_scores(winning_scores, losing_scores)

func clear():
	for entry in entry_container.get_children():
		entry.free()

func select(index, clear_existing = true):
	if clear_existing:
		for entry in entry_container.get_children():
			entry.deselect()
	entry_container.get_child(index).select()
	update_selection()
	update_selection_draw()
	emit_signal("item_selected", selection)

func clear_selection():
	for entry in entry_container.get_children():
		entry.deselect()
	update_selection()
	update_selection_draw()

func update_selection():
	selection.clear()
	for entry in entry_container.get_children():
		if entry.is_selected:
			selection.append(entry.get_index())

func update_selection_draw():
	for entry in entry_container.get_children():
		if entry.is_selected:
			entry.draw_selection()
		else:
			entry.draw_selection(false)

func update_indices():
	for match_entry in entry_container.get_children():
		match_entry.update_index()
