extends HBoxContainer

signal card_edit_pressed
signal card_delete_pressed

@onready var edit_button = $CardPanel/HBoxContainer/CardButtons/EditButton
@onready var delete_button = $CardPanel/HBoxContainer/CardButtons/DeleteButton
@onready var copy_results_button = $CardPanel/HBoxContainer/CardButtons/CopyResultsButton
@onready var winning_score_labels = $CardPanel/HBoxContainer/Scores/Panel/WinningScoreLabels
@onready var losing_score_labels = $CardPanel/HBoxContainer/Scores/Panel2/LosingScoreLabels
@onready var index_label = $IndexLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	update_index()
	copy_results_button.connect("pressed", _on_copy_results_button_pressed)
	edit_button.connect("pressed", emit_card_edit)
	delete_button.connect("pressed", _on_delete_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_copy_results_button_pressed():
	var clipboard = ""
	for label in winning_score_labels.get_children():
		clipboard += label.text
		if label.get_index() < winning_score_labels.get_child_count() - 1:
			clipboard += ", "
	clipboard += "\n"
	for label in losing_score_labels.get_children():
		clipboard += label.text
		if label.get_index() < winning_score_labels.get_child_count() - 1:
			clipboard += ", "
	DisplayServer.clipboard_set(clipboard)

func emit_card_edit():
	emit_signal("card_edit_pressed", get_index())

func _on_delete_button_pressed():
	emit_signal("card_delete_pressed", get_index())
	queue_free()

func set_score_label(index, winning, score):
	var new_text = ""
	if score > 0:
		new_text = "+" + str(score)
	else:
		new_text = str(score)
	if winning:
		winning_score_labels.get_child(index).text = new_text
	else:
		losing_score_labels.get_child(index).text = new_text

func set_scores(winning_scores, losing_scores):
	for i in winning_scores.size():
		set_score_label(i, true, winning_scores[i])
	for i in losing_scores.size():
		set_score_label(i, false, losing_scores[i])

func update_index():
	index_label.text = str(get_index() + 1)
