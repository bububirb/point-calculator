extends Button

var font_size_max = 24.0
var font_size_min = 8.0
var expansion = 54.0
var x_position

var offscreen_x_offset = 72.0

@onready var onscreen_x_offset = position.x - DisplayServer.window_get_size().x
@onready var x_offset = onscreen_x_offset

@onready var x_size = size.x

# Called when the node enters the scene tree for the first time.
func _ready():
	update_x_position()
	if OS.get_name() == "Windows":
		mouse_entered.connect(expand_button)
		mouse_exited.connect(contract_button)
	elif OS.get_name() == "Android":
		expand_button()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func expand_button():
	var size_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	size_tween.tween_property(self, "size:x", x_size + expansion, 0.4)
	var position_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	position_tween.tween_property(self, "position:x", x_position - expansion, 0.4)
	var font_size_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	font_size_tween.tween_property(self, "theme_override_font_sizes/font_size", font_size_max, 0.4)

func contract_button():
	var size_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	size_tween.tween_property(self, "size:x", x_size, 0.4)
	var position_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	position_tween.tween_property(self, "position:x", x_position, 0.4)
	var font_size_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	font_size_tween.tween_property(self, "theme_override_font_sizes/font_size", font_size_min, 0.4)

func update_x_position():
	if OS.get_name() == "Windows":
		var window_size = DisplayServer.window_get_size()
		x_position = window_size.x + x_offset
		contract_button()
	if OS.get_name() == "Android":
		var safe_area = DisplayServer.get_display_safe_area()
		x_position = safe_area.size.x + safe_area.position.x + x_offset
		expand_button()

func hide_button():
	x_offset = offscreen_x_offset
	update_x_position()

func show_button():
	x_offset = onscreen_x_offset
	update_x_position()
