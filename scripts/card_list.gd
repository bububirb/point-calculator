extends Control

var scroll_offset = 0.0
var scroll_direction = 0

signal scrolling
signal card_edit
signal card_delete

@onready var scroll_container = $ScrollContainer
@onready var card_container = $ScrollContainer/CardContainer

var card_scene = load("res://scenes/card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (scroll_offset == 0) != (scroll_container.scroll_vertical == 0):
		emit_scroll_signal()
	scroll_offset = scroll_container.scroll_vertical

func emit_scroll_signal():
	emit_signal("scrolling", scroll_container.scroll_vertical)

func _on_card_edit_pressed(index):
	emit_signal("card_edit", index)

func _on_card_delete_pressed(index):
	emit_signal("card_delete", index)

func load_card(match_data):
	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)
	card_instance.set_scores(match_data.winning_scores, match_data.losing_scores)
	card_instance.connect("card_edit_pressed", _on_card_edit_pressed)
	card_instance.connect("card_delete_pressed", _on_card_delete_pressed)

func add_card():
	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)
	emit_signal("card_edit", card_container.get_child_count() - 1)
	card_instance.connect("card_edit_pressed", _on_card_edit_pressed)
	card_instance.connect("card_delete_pressed", _on_card_delete_pressed)

func delete_card(index):
	card_container.get_child(index).queue_free()

func set_card_scores(index, winning_scores, losing_scores):
	card_container.get_child(index).set_scores(winning_scores, losing_scores)
