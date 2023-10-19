extends PanelContainer

signal override_added
signal override_player_changed
signal override_score_changed
signal override_relative_toggled
signal override_deleted

var override_entry_scene = load("res://scenes/override_entry.tscn")

var player_names = []
var pinned = []

@onready var add_override_button = $VBoxContainer/AddOverrideButton
@onready var override_entry_container = $VBoxContainer/OverrideEntryContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	add_override_button.connect("pressed", _on_add_override_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_add_override_button_pressed():
	add_override().update_player_options(player_names, pinned, "")
	emit_signal("override_added")

func add_override():
	var override_entry = override_entry_scene.instantiate()
	override_entry_container.add_child(override_entry)
	override_entry.connect("player_changed", _on_override_entry_player_changed)
	override_entry.connect("score_changed", _on_override_entry_score_changed)
	override_entry.connect("relative_toggled", _on_override_entry_relative_toggled)
	override_entry.connect("deleted", _on_override_entry_deleted)
	return override_entry

func load_overrides(overrides):
	for override in overrides:
		var override_entry = add_override()
		override_entry.update_player_options(player_names, pinned, override.player_id)
		override_entry.set_score(override.score)
		override_entry.set_relative(override.relative)

func clear_overrides():
	for override_entry in override_entry_container.get_children():
		override_entry.free()

func _on_override_entry_player_changed(index, player_id):
	emit_signal("override_player_changed", index, player_id)

func _on_override_entry_score_changed(index, score):
	emit_signal("override_score_changed", index, score)

func _on_override_entry_relative_toggled(index, relative):
	emit_signal("override_relative_toggled", index, relative)

func _on_override_entry_deleted(index):
	emit_signal("override_deleted", index)

func refresh_player_options():
	for override_entry in override_entry_container.get_children():
		override_entry.refresh_player_options(player_names, pinned)
