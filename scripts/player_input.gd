extends HBoxContainer

signal weight_changed

@onready var weight_input = $WeightInput
@onready var score_label = $ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	weight_input.connect("text_changed", _on_weight_input_text_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_weight_input_text_changed(new_text):
	if new_text == "":
		new_text = "1"
	var weight = float(new_text)
	emit_signal("weight_changed", get_index(), weight)

func set_weight(weight):
	weight_input.text = str(weight)

func set_score(score):
	if score > 0:
		score_label.text = "+" + str(score)
	else:
		score_label.text = str(score)
