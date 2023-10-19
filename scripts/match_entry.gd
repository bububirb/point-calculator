extends HBoxContainer

signal entry_edit_pressed
signal entry_duplicate_pressed
signal selected

var is_selected = false
const MIN_HEIGHT = 108.0
const TWEEN_DURATION = 0.2

@onready var entry_button = $EntryButton
@onready var edit_button = $EntryButton/HBoxContainer/VFlowContainer/EditButton
@onready var duplicate_button = $EntryButton/HBoxContainer/VFlowContainer/DuplicateButton
@onready var winning_score_labels = $EntryButton/HBoxContainer/Scores/Panel/WinningScoreLabels
@onready var losing_score_labels = $EntryButton/HBoxContainer/Scores/Panel2/LosingScoreLabels
@onready var index_label = $IndexLabel
@onready var selection_draw = $EntryButton/SelectionDraw

# Called when the node enters the scene tree for the first time.
func _ready():
	update_index()
	entry_button.connect("pressed", _on_entry_button_pressed)
	edit_button.connect("pressed", emit_entry_edit)
	duplicate_button.connect("pressed", _on_duplicate_button_pressed)
	expand()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_entry_button_pressed():
	emit_signal("selected", get_index())

func emit_entry_edit():
	emit_signal("entry_edit_pressed", get_index())

func _on_duplicate_button_pressed():
	emit_signal("entry_duplicate_pressed", get_index())

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

func select():
	is_selected = true
	draw_selection(is_selected)

func deselect():
	is_selected = false
	draw_selection(is_selected)

func draw_selection(value = true):
	selection_draw.visible = value

func expand():
	modulate.a = 0.0
	entry_button.custom_minimum_size.y = 64.0
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(entry_button, "custom_minimum_size:y", MIN_HEIGHT, TWEEN_DURATION)
	tween.tween_property(self, "modulate:a", 1.0, TWEEN_DURATION)
