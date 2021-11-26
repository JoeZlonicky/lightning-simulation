extends Sprite


export (float) var BRANCH_CHANCE = 0.05
export (float) var TIME_BETWEEN_STRIKES = 0.1
export (float) var NUM_OF_STRIKES = 200
export (Vector2) var CELL_WEIGHT_RANGE = Vector2(1.0, 10.0)

const GRID_SIZE = Vector2(20, 20)
const GRID_SCALE = 20.0
const GRID_COLOR = Color(1.0, 1.0, 1.0, 0.2)
const LINE_WIDTH = 2.0
const LINE_COLOR = Color.white
const SEGMENT_MAX_ANGLE = 16.0 / 180.0 * PI
const REMENANT_WEIGHT = 2.0


class LightningPath:
	var path = PoolVector2Array()
	var ids = PoolIntArray()
	var draw_path = PoolVector2Array()
	var tier = 1
	
	func add_point(id, point):
		ids.append(id)
		path.append(point)


var lightning_paths = []
var remenant_weights = []
var astar_grid = AStar2D.new()
var start_id = 0
var end_id = GRID_SIZE.x * GRID_SIZE.y - 1


func _ready():
	randomize()
	var i = 0
	
	for y in GRID_SIZE.y:
		remenant_weights.append([])
		for x in GRID_SIZE.x:
			var pos = GRID_SCALE * Vector2(x, y) - GRID_SIZE * GRID_SCALE / 2.0
			astar_grid.add_point(i, pos)
			remenant_weights[y].append(0.0)
			i += 1
	
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			i = y * GRID_SIZE.y + x
			if x % int(GRID_SIZE.x) != GRID_SIZE.x - 1:
				astar_grid.connect_points(i, i + 1, true)
			if y % int(GRID_SIZE.y) != GRID_SIZE.y - 1:
				astar_grid.connect_points(i, i + GRID_SIZE.x, false)


func generate():
	lightning_paths.clear()
	for i in NUM_OF_STRIKES:
		strike()
		if i != NUM_OF_STRIKES - 1:
			yield(get_tree().create_timer(TIME_BETWEEN_STRIKES), "timeout")
	
	
	
func strike():
	randomize()
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			remenant_weights[y][x] = 0.0
	
	for path in lightning_paths:
		for p_idx in path.ids:
			var x = int(p_idx % int(GRID_SIZE.x))
			var y = int(p_idx / GRID_SIZE.y)
			remenant_weights[y][x] = REMENANT_WEIGHT
	
	lightning_paths.clear()
	
	var i = 0
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var w = rand_range(CELL_WEIGHT_RANGE.x, CELL_WEIGHT_RANGE.y)
			w = clamp(w - remenant_weights[y][x], CELL_WEIGHT_RANGE.x, CELL_WEIGHT_RANGE.y)
			astar_grid.set_point_weight_scale(i, w)
			i += 1
	create_lightning(start_id, end_id, 1.0)
	update()


func create_lightning(from, to, tier, add_to_start=-1):
	var lightning_path = LightningPath.new()
	lightning_path.tier = tier
	if add_to_start > -1:
		lightning_path.add_point(add_to_start, astar_grid.get_point_position(add_to_start))
	var astar_path = astar_grid.get_id_path(from, to)
	for i in astar_path.size():
		var p_idx = astar_path[i]
		lightning_path.add_point(p_idx, astar_grid.get_point_position(p_idx))
		if randf() < BRANCH_CHANCE and i < astar_path.size() - 1:
			var neighbors = astar_grid.get_point_connections(p_idx)
			if neighbors.size() < 2:
				continue
			for neighbor in neighbors:
				var branch_path = astar_grid.get_id_path(neighbor, to)
				if branch_path.size() < 2:
					continue
				if branch_path[0] == astar_path[i+1]:
					continue
				if branch_path[1] == p_idx:
					continue
				create_lightning(neighbor, to, tier * 2, p_idx)
				break
	
	lightning_paths.append(lightning_path)

func _draw():
#	for point_index in astar_grid.get_points():
#		var pos = astar_grid.get_point_position(point_index)
#		draw_circle(pos, 1.0, GRID_COLOR)
	
	for lightning in lightning_paths:
		var color = LINE_COLOR
		color.a = 1.0 / lightning.tier
		for p_idx in lightning.path.size() - 1:
			var p1 = lightning.path[p_idx]
			var p3 = lightning.path[p_idx+1]
			if lightning.tier > 1:
				seed(int(p1.x) + int(p1.y))
			var p2 = p1 + (p3-p1)/2.0 + GRID_SCALE * tan(rand_range(-SEGMENT_MAX_ANGLE, SEGMENT_MAX_ANGLE)) * (p3-p1).tangent().normalized()
			draw_line(p1, p2, color, LINE_WIDTH)
			draw_line(p2, p3, color, LINE_WIDTH)
