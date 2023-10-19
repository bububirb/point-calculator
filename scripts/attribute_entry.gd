extends Button

signal selected

var is_selected := false

var indent := 0
var indent_size := 8

@onready var key_label = $Labels/KeyLabel
@onready var value_label = $Labels/ValueLabel
@onready var selection_draw = $SelectionDraw
@onready var indent_margin = $Labels/IndentMargin

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", _on_pressed)
	update_indent()

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

func set_indent(value):
	indent = value
	update_indent()

func get_indent():
	return indent

func update_indent():
	indent_margin.custom_minimum_size.x = indent * indent_size

func set_key(key):
	key_label.text = str(key)

func set_value(value):
	value_label.text = str(value)

func get_key():
	return key_label.text

func get_value():
	return value_label.text

func draw_selection(value = true):
	selection_draw.visible = value
