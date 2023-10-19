extends Button
class_name FilteredOptionButton

signal item_selected

@export var MAX_HEIGHT := 480.0

var option_scene = load("res://scenes/option.tscn")

var vertical_margin = 12

var item_count = 0

@onready var popup = $Popup
@onready var option_panel = $Popup/OptionPanel
@onready var filter_input = $Popup/OptionPanel/VBoxContainer/FilterInput
@onready var options = %Options
@onready var add_option_button = %AddOptionButton

func _ready():
	pass

func _process(_delta):
	pass

func _on_pressed():
	update_popup_size()
	popup.show()
	filter_input.call_deferred("grab_focus")


func _on_filter_input_text_changed(new_text):
#	if new_text == "":
#		add_option_button.hide()
#	else:
#		add_option_button.show()
#	add_option_button.text = new_text
	filter_options(new_text)

func _on_filter_input_text_submitted(new_text):
	if new_text != "":
		if get_sorted_options().size() >= 1:
			select_option(get_sorted_options()[0])

func filter_options(filter_text):
	for option in options.get_children():
		var filter = "*" + filter_text.replace(" ", "*") + "*"
		option.visible = option.text.matchn(filter) or filter_text == ""
	sort_options()

func get_item_text(idx):
	var option = get_option(idx)
	if option:
		return option.text

func update_popup_size():
	options.reset_size()
	var window_size = DisplayServer.window_get_size()
	popup.size.x = min(size.x, window_size.x)
	popup.size.y = min(options.size.y + filter_input.size.y + vertical_margin, window_size.y, MAX_HEIGHT)
	popup.position = global_position.clamp(Vector2i(0, 0), window_size - popup.size)

func get_sorted_options():
	var sorted_options = []
	for option in options.get_children():
		if option.visible:
			sorted_options.append(option)
	sorted_options.sort_custom(option_sort_function)
	return sorted_options

func sort_options():
	var sorted_options = get_sorted_options()
	for option in sorted_options:
		options.remove_child(option)
	for option in sorted_options:
		options.add_child(option)

func option_sort_function(a, b):
	var weight_a = 0
	var weight_b = 0
	var filter_text = filter_input.text.strip_edges()
	weight_b += int(b.pinned) * 32
	weight_a += int(a.pinned) * 32
	weight_a += int(a.text.contains(filter_text)) * 16
	weight_b += int(b.text.contains(filter_text)) * 16
	weight_a += int(a.text.matchn(filter_text)) * 8
	weight_b += int(b.text.matchn(filter_text)) * 8
	filter_text = filter_text + "*"
	weight_a += int(a.text.matchn(filter_text)) * 4
	weight_b += int(b.text.matchn(filter_text)) * 4
	filter_text = "*" + filter_text.replace(" ", "*")
	weight_a += int(a.text.matchn(filter_text))
	weight_b += int(b.text.matchn(filter_text))
	weight_a += int(a.id < b.id)
	return weight_a > weight_b

func _on_add_option_button_pressed():
	add_item(add_option_button.text)
	select_option(add_option_button.text)

func add_item(option_name, pinned = false):
	var option_node = option_scene.instantiate()
	option_node.pinned = pinned
	option_node.text = option_name
	options.add_child(option_node)
	option_node.connect("pressed", select_option.bind(option_node))
	item_count += 1

func select_option(option):
	if option == null:
		text = ""
	else:
		var option_name = option.text
		text = option_name
		emit_signal("item_selected", option.id)
	_close_option_panel()

func select(idx):
	if idx == -1:
		select_option(null)
	else:
		var option = get_option(idx)
		if option:
			select_option(option)

func get_option(idx):
	for option in options.get_children():
		if option.id == idx:
			return option

func clear(clear_selection = true):
	for option in options.get_children():
		option.free()
	if clear_selection:
		select(-1)
	item_count = 0

func _close_option_panel():
	popup.hide()
	filter_input.text = ""
	filter_options("")
#	add_option_button.text = ""
