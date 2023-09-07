extends Panel

@export var margin := 32.0
@export var margin_width := 2.0
@export var margin_color := Color(0.25, 0.25, 0.25)
@export var grid_width := 1.0
@export var grid_color := Color(1.0, 1.0, 1.0, 0.1)
@export var subdivisions_x := 3
@export var subdivisions_y := 10
@export var minimum_spacing := 48.0

@export var point_radius := 4.0
@export var point_color = Color.DEEP_SKY_BLUE

@export var bar_color = Color.DODGER_BLUE
@export var bar_width = 4.0

var label_font = preload("res://resources/fonts/product_sans_bold.ttf")
var label_size := 13
var label_offset := Vector2(-64.0, -22.0)
var label_width := 128.0
var axis_label_offset := Vector2(-36.0, 0.0)
var axis_label_width := 32.0

var points : PackedVector2Array = []
var labels : PackedStringArray = []

var min_x := 0.0
var max_x := 1.0
var min_y := 0.0
var max_y := 1.0

var vertical_size := 1.0
var spacing = 0.0

@onready var top_left := Vector2(margin, margin)
@onready var top_right := Vector2(size.x - margin, margin)
@onready var bottom_left := Vector2(margin, size.y - margin)
@onready var bottom_right := Vector2(size.x - margin, size.y - margin)

@onready var left = margin
@onready var right := size.x - (margin * 2)
@onready var top = margin
@onready var bottom := size.y - (margin * 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("resized", _on_resized)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_resized():
	top_left = Vector2(margin, margin)
	top_right = Vector2(size.x - margin, margin)
	bottom_left = Vector2(margin, size.y - margin)
	bottom_right = Vector2(size.x - margin, size.y - margin)
	
	left = margin
	right = size.x - margin
	top = margin
	bottom = size.y - margin
	
	queue_redraw()

func _draw():
	subdivisions_x = 3
	subdivisions_y = 10
	update_range()
	draw_grid()
	draw_borders()
	
	draw_points()

func draw_borders():
	draw_line(top_left, top_right, margin_color, margin_width)
	draw_line(bottom_left, bottom_right, margin_color, margin_width)
	draw_line(top_left, bottom_left, margin_color, margin_width)
	draw_line(top_right, bottom_right, margin_color, margin_width)

func draw_grid():
	for i in subdivisions_x - 1:
		var factor = float(i + 1) / float(subdivisions_x)
		draw_line(lerp(top_left, top_right, factor), lerp(bottom_left, bottom_right, factor), grid_color, grid_width)
	for i in subdivisions_y - 1:
		var factor = float(i + 1) / float(subdivisions_y)
		draw_line(lerp(top_left, bottom_left, factor), lerp(top_right, bottom_right, factor), grid_color, grid_width)

func plot_point(value, label):
	points.append(Vector2(points.size(), value))
	labels.append(label)
	custom_minimum_size.x = margin * 2 + (points.size() + 1) * minimum_spacing
	queue_redraw()

func draw_points():
	for i in points.size():
		var x = remap(float(points[i].x), min_x, max_x, left + spacing, right - spacing)
		var y = remap(float(points[i].y), min_y, max_y, bottom, top)
		var location = Vector2(x, y)
		draw_line(Vector2(x, bottom), location, bar_color, bar_width)
		draw_circle(location, point_radius - 1.0, point_color)
		draw_arc(location, point_radius - 1.0, 0.0, TAU, 32, point_color, 1.0, true)
		draw_multiline_string(label_font, location + label_offset, labels[i] + "\n" + str(points[i].y), HORIZONTAL_ALIGNMENT_CENTER, label_width, label_size)
	for i in subdivisions_y + 1:
		var factor = float(i) / float(subdivisions_y)
		var location = lerp(bottom_left, top_left, factor) + axis_label_offset
		var value = lerp(min_y, max_y, factor)
#		if value >= 10000:
#			pow(10.0, ceilf(log((max_y - min_y) / 10.0) / log(10.0)))
		var text = str(value)
		draw_string(label_font, location, text, HORIZONTAL_ALIGNMENT_RIGHT, axis_label_width, label_size)

func update_range():
	min_x = 0.0
	max_x = 1.0
	min_y = 0.0
	max_y = 1.0
	for point in points:
		if point.x < min_x:
			min_x = point.x
		if point.x > max_x:
			max_x = point.x
		if point.y < min_y:
			min_y = point.y
		if point.y > max_y:
			max_y = point.y
	vertical_size = pow(10.0, ceilf(log((max_y - min_y) / 10.0) / log(10.0)))
	max_y = ceilf(max_y / vertical_size) * vertical_size
	min_y = floorf(min_y / vertical_size) * vertical_size
	subdivisions_x = int(max_x - min_x) + 2
	subdivisions_y = int((max_y - min_y) / vertical_size)
	spacing = (right - left) / subdivisions_x

func plot_set(set_values : Array, set_labels : Array):
	for i in set_values.size():
		plot_point(set_values[i], set_labels[i])

func clear():
	points = []
	labels = []
	queue_redraw()

func recalculate_x():
	for i in points.size():
		points[i] = Vector2(i, points[i].y)

func remove(index):
	points.remove_at(index)
	labels.remove_at(index)
	recalculate_x()
	queue_redraw()
