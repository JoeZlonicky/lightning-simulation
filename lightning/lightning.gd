extends Sprite


export (float) var TIME_BETWEEN_STRIKES = 0.1
export (float) var NUM_STRIKES = 1
export (float) var BRANCH_CHANCE = 0.05

const GRID_SIZE = Vector2(100, 100)
const GRID_SCALE = 2.0
const GRID_COLOR = Color.white
const LINE_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const LINE_WIDTH = 1.0

class LightningPath:
	var path = PoolVector2Array()
	var opacity = 1.0
	var pi
	
	func add_point(point):
		path.append(point)


var grid_points = PoolVector2Array()
var weights = PoolRealArray()
var image = Image.new()
var paths = []


func _ready():
	randomize()
	
	image.create(GRID_SIZE.x * GRID_SCALE, GRID_SIZE.y * GRID_SCALE, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.new()
	
	for y in GRID_SIZE.x:
		for x in GRID_SIZE.y:
			grid_points.append(Vector2(x * GRID_SCALE, y * GRID_SCALE))

	position.x = (1280.0 / 2.0 - (GRID_SIZE.x * GRID_SCALE * scale.x) / 2.0)
	position.y = (720 / 2.0 - (GRID_SIZE.y * GRID_SCALE * scale.y) / 2.0)
	
	generate_weights()
	generate_lightning()


func generate():
	for i in NUM_STRIKES:
		generate_weights()
		generate_lightning()
		if i != NUM_STRIKES - 1:
			yield(get_tree().create_timer(TIME_BETWEEN_STRIKES), "timeout")


func generate_weights():
	weights.resize(0)
	image.lock()
	for y in GRID_SIZE.x:
		for x in GRID_SIZE.y:
			var w = rand_range(0.1, 1.0)
			weights.append(w)
			image.set_pixel(x * GRID_SCALE, y * GRID_SCALE, GRID_COLOR * w)
	image.unlock()
	
	texture.create_from_image(image)


func generate_lightning():
	paths = [LightningPath.new()]
	
	var yi = 0
	paths[0].pi = int(GRID_SIZE.x / 2.0)
	paths[0].add_point(grid_points[paths[0].pi])
	
	while yi < GRID_SIZE.y - 1:
		for i in paths.size():
			var l_path = paths[i]
			var next = get_next_points(l_path.pi)
			if not next:
				break
			next.sort_custom(self, "sort_by_weight")
			
			if randf() < BRANCH_CHANCE and next.size() > 1:
				var new_path = LightningPath.new()
				new_path.opacity = l_path.opacity * 0.5
				new_path.add_point(grid_points[l_path.pi])
				new_path.pi = next[1]
				new_path.add_point(grid_points[new_path.pi])
				paths.append(new_path)
			
			l_path.pi = next[0]
			l_path.add_point(grid_points[l_path.pi])
			
		yi += 1


func get_next_points(pi):
	var points = []
	var yi = int(pi / GRID_SIZE.x)
	var xi = pi - int(yi * GRID_SIZE.x)
	if xi < GRID_SIZE.x - 1:
		points.append((yi+1) * GRID_SIZE.x + xi + 1)
	if xi > 0:
		points.append((yi+1) * GRID_SIZE.x + xi - 1)
	points.append((yi+1) * GRID_SIZE.x + xi)
	return points


func _draw():
	for l_path in paths:
		var color = LINE_COLOR
		color.a *= l_path.opacity
		draw_polyline(l_path.path, color, LINE_WIDTH)


func sort_by_weight(a, b):
	if weights[a] < weights[b]:
		return true
	return false
