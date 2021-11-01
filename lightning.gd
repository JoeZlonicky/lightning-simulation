extends Sprite


const GRID_SIZE = Vector2(50, 50)
const GRID_SCALE = 5.0
const GRID_COLOR = Color.white
const LINE_COLOR = Color(1.0, 0.0, 0.0, 0.4)
const LINE_WIDTH = 1.0

var grid_points = PoolVector2Array()
var image = Image.new()


func _ready():
	image.create(GRID_SIZE.x * GRID_SCALE, GRID_SIZE.y * GRID_SCALE, false, Image.FORMAT_RGBA8)
	image.lock()
	
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			grid_points.append(Vector2(x * GRID_SCALE, y * GRID_SCALE))
			image.set_pixel(x * GRID_SCALE, y * GRID_SCALE, GRID_COLOR)
	
	image.unlock()
	
	texture = ImageTexture.new()
	texture.create_from_image(image)
	
	position.x = (1280.0 / 2.0 - (GRID_SIZE.x * GRID_SCALE * scale.x) / 2.0)
	position.y = (720 / 2.0 - (GRID_SIZE.y * GRID_SCALE * scale.y) / 2.0)


func _draw():
	draw_line(grid_points[2499], grid_points[0], LINE_COLOR, LINE_WIDTH, true)
