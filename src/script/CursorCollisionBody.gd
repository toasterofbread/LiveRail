extends StaticBody2D
class_name CursorCollisionBody

func _ready():
	set_collision_layer_value(0, true)
	set_collision_mask_value(0, true)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(3, 3)
	add_child(shape)

func _physics_process(delta: float):
	global_position = get_global_mouse_position()
