extends HBoxContainer

signal player_changed
signal score_changed
signal relative_toggled
signal deleted

const TWEEN_DURATION = 0.25

@onready var player_option = $PlayerOption
@onready var override_input = $HBoxContainer/OverrideInput
@onready var relative_check_box = $HBoxContainer/RelativeCheckBox
@onready var delete_button = $HBoxContainer/DeleteButton

# Called when the node enters the scene tree for the first time.
func _ready():
	player_option.connect("item_selected", _on_player_option_item_selected)
	delete_button.connect("pressed", _on_delete_button_pressed)
	override_input.connect("text_changed", _on_override_input_text_changed)
	relative_check_box.connect("toggled", _on_relative_check_box_toggled)
	expand()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_player_option_item_selected(index):
	var player_id = player_option.get_item_text(index)
	emit_signal("player_changed", get_index(), player_id)

func _on_delete_button_pressed():
	emit_signal("deleted", get_index())
	queue_free()

func _on_override_input_text_changed(new_text):
	var score = float(new_text)
	emit_signal("score_changed", get_index(), score)

func _on_relative_check_box_toggled(button_pressed):
	emit_signal("relative_toggled", get_index(), button_pressed)

func set_score(score):
	override_input.text = str(score)

func set_relative(toggled):
	relative_check_box.button_pressed = toggled

func update_player_options(player_names, pinned, selection_id):
	player_option.clear()
	for i in player_names.size():
		player_option.add_item(player_names[i], pinned[i])
	var selection = player_names.find(selection_id)
	if selection < player_option.item_count:
		player_option.select(selection)
	else:
		player_option.select(-1)
	player_option.sort_options()

func refresh_player_options(player_names, pinned):
	player_option.clear(false)
	for i in player_names.size():
		player_option.add_item(player_names[i], pinned[i])
	player_option.sort_options()

func expand():
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, TWEEN_DURATION)
