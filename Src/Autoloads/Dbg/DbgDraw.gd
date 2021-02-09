extends Control

enum DrawType {
	VECTOR3,
	VECTOR2,
	POINT3,
	POINT2,
}

class Drawable:
	var type: int			# Draw type
	var object: Object  	# The node to follow
	var property: String  	# The property to draw
	var is_method: bool 	# is it a method
	var scale: float  		# Scale factor
	var width: int  		# Line width
	var color: Color  		# Draw color

	func _init(
			_type: int, 
			_object: Object, 
			_property: String, 
			_is_method: bool, 
			_scale: float, _width: int, 
			_color: Color):
		type = _type
		object = _object
		property = _property
		is_method = _is_method
		scale = _scale
		width = _width
		color = _color
	
	func get_quantity():
		if is_method:
			return object.call(property)
		else:
			return object.get(property)

var drawables = []  # Array to hold all registered drawables.
var active_3d_camera = null setget set_active_3d_camera
onready var screen_res := get_viewport().size

var cleanup_initialised := false

func _cleanup():
	drawables = []
	active_3d_camera = null
	cleanup_initialised = false

func _startup():
	if not cleanup_initialised:
		cleanup_initialised = true
		active_3d_camera = get_viewport().get_camera()
		var _err := get_tree().current_scene.connect("tree_exiting", self, "_cleanup")

func set_active_3d_camera(val: Camera):
	active_3d_camera = val

# Dbg.draw.add_vector3d(self, "velocity", false, 1, 4, Color(0,1,0, 0.5))
func add_vector3d(object: Object, property: String, is_method: bool = false, scale: float = 0.1, width: int = 4, color: Color = Color(0,1,0, 0.5)):
	_startup()
	drawables.append(Drawable.new(DrawType.VECTOR3, object, property, is_method, scale, width, color))

# Dbg.draw.add_vector2d(self, "velocity", false, 1, 4, Color(0,1,0, 0.5))
func add_vector2d(object: Object, property: String, is_method: bool = false, scale: float = 0.1, width: int = 4, color: Color = Color(0,1,0, 0.5)):
	_startup()
	drawables.append(Drawable.new(DrawType.VECTOR2, object, property, is_method, scale, width, color))

func add_point3d(object: Object, property: String, is_method: bool = false, scale: float = 0.1, width: int = 4, color: Color = Color(0,1,0, 0.5)):
	_startup()
	drawables.append(Drawable.new(DrawType.POINT3, object, property, is_method, scale, width, color))

func add_point2d(object: Object, property: String, is_method: bool = false, scale: float = 0.1, width: int = 4, color: Color = Color(0,1,0, 0.5)):
	_startup()
	drawables.append(Drawable.new(DrawType.POINT2, object, property, is_method, scale, width, color))

func draw_triangle(pos, dir, size, color):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = PoolVector2Array([a, b, c])
	draw_polygon(points, PoolColorArray([color]))

func _ready() -> void:
	if OS.is_debug_build():
		set_process(true)
		active_3d_camera = get_viewport().get_camera()
	else:
		set_process(false)

func _process(_delta: float) -> void:
	if not visible:
		return
	update()

func _draw():
	for drawable in drawables:
		if drawable == null:
			drawables.erase(drawable)
			continue
		match drawable.type:
			DrawType.VECTOR2:
				var start = drawable.object.global_transform.origin
				var end = drawable.object.global_transform.origin + drawable.get_quantity() * drawable.scale
				draw_line(start, end, drawable.color, drawable.width)
				draw_triangle(end, start.direction_to(end), drawable.width*2, drawable.color)
			DrawType.VECTOR3:
				var start = active_3d_camera.unproject_position(drawable.object.global_transform.origin)
				var end = active_3d_camera.unproject_position(
					drawable.object.global_transform.origin + drawable.get_quantity() * drawable.scale)
				if end.x >= 0 and end.x < screen_res.x and end.y >= 0 and end.y < screen_res.y:
					draw_line(start, end, drawable.color, drawable.width)
					draw_triangle(end, start.direction_to(end), drawable.width*2, drawable.color)
			DrawType.POINT3:
				var point = active_3d_camera.unproject_position(drawable.get_quantity())
				if point.x >= 0 and point.x < screen_res.x and point.y >= 0 and point.y < screen_res.y:
					draw_circle(point, drawable.width, drawable.color)
			DrawType.POINT2:
				# TODO
				pass
			
