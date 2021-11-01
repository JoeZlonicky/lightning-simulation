extends Sprite


const GRID_SIZE = Vector2(50, 50)
const GRID_SCALE = 5.0
const GRID_COLOR = Color.white
const LINE_COLOR = Color(1.0, 0.0, 0.0, 0.4)
const LINE_WIDTH = 1.0

var grid_points = PoolVector2Array()
var weights = PoolRealArray()
var image = Image.new()

var path = PoolVector2Array()

func _ready():
	randomize()
	
	image.create(GRID_SIZE.x * GRID_SCALE, GRID_SIZE.y * GRID_SCALE, false, Image.FORMAT_RGBA8)
	image.lock()
	
	for y in GRID_SIZE.x:
		for x in GRID_SIZE.y:
			grid_points.append(Vector2(x * GRID_SCALE, y * GRID_SCALE))
			var w = rand_range(0.1, 1.0)
			weights.append(w)
			image.set_pixel(x * GRID_SCALE, y * GRID_SCALE, GRID_COLOR * w)
	
	image.unlock()
	
	texture = ImageTexture.new()
	texture.create_from_image(image)
	
	position.x = (1280.0 / 2.0 - (GRID_SIZE.x * GRID_SCALE * scale.x) / 2.0)
	position.y = (720 / 2.0 - (GRID_SIZE.y * GRID_SCALE * scale.y) / 2.0)
	
	create_path()

func create_path():
	var pi = int(GRID_SIZE.x / 2.0)
	var yi = 0
	path.append(grid_points[pi])
	while yi < GRID_SIZE.y - 1:
		var next = get_next_points(pi)
		next.sort_custom(self, "sort_by_weight")
		
		pi = next[0]
		path.append(grid_points[pi])
		yi += 1


func get_next_points(pi):
	var points = []
	var yi = int(pi / GRID_SIZE.x)
	var xi = pi - yi * GRID_SIZE.x
	if xi < GRID_SIZE.x - 1:
		points.append((yi+1) * GRID_SIZE.x + xi + 1)
	if xi > 0:
		points.append((yi+1) * GRID_SIZE.x + xi - 1)
	points.append((yi+1) * GRID_SIZE.x + xi)
	return points


func _draw():
	pass
	#draw_polyline(path, LINE_COLOR, LINE_WIDTH)


func sort_by_weight(a, b):
	if weights[a] < weights[b]:
		return true
	return false
