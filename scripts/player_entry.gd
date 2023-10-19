extends Button

signal selected

var is_selected = false

const TWEEN_DURATION = 0.4
const MIN_HEIGHT = 32.0

@onready var player_name_label = $Labels/PlayerNameLabel
@onready var pin_icon = $Labels/PinIcon
@onready var selection_draw = $SelectionDraw

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", _on_pressed)
#	expand()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_pressed():
	emit_signal("selected", get_index())

func select():
	is_selected = true
	draw_selection(is_selected)

func deselect():
	is_selected = false
	draw_selection(is_selected)

func set_player_name(player_name):
	player_name_label.text = player_name

func set_pinned(pinned):
	pin_icon.visible = pinned

func get_player_name():
	return player_name_label.text

func get_pinned():
	return pin_icon.visible

func draw_selection(value = true):
	selection_draw.visible = value

func expand():
	modulate.a = 0.0
	custom_minimum_size.y = 16.0
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT).set_parallel()
	tween.tween_property(self, "custom_minimum_size:y", MIN_HEIGHT, TWEEN_DURATION)
	tween.tween_property(self, "modulate:a", 1.0, TWEEN_DURATION)
