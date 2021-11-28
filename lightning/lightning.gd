extends Sprite


signal simulation_completed

export (float) var MAX_BRANCH_CHANCE = 0.5
export (float) var TIME_BETWEEN_STRIKES = 0.1
export (float) var NUM_OF_STRIKES = 200
export (Curve) var BRANCH_CHANCE_CURVE
export (Vector2) var CELL_WEIGHT_RANGE = Vector2(1.0, 10.0)

const GRID_SIZE = Vector2(10, 10)
const GRID_SCALE = 40.0
const GRID_POINTS_COLOR = Color(1.0, 1.0, 1.0, 0.6)
const PRIMARY_LINE_WIDTH = 3.0
const SECONDARY_LINE_WIDTH = 15.0
const PRIMARY_LINE_COLOR = Color.white
const SECONDARY_LINE_COLOR = Color.white / 4.0
const SEGMENT_MAX_ANGLE = 16.0 / 180.0 * PI
const PRIMARY_REMENANT_WEIGHT = 3.0
const SECONDARY_REMENANT_WEIGHT = 2.0


class LightningPath:
	var points = PoolVector2Array()
	var point_ids = PoolIntArray()
	var draw_points = PoolVector2Array()
	var tier = 1
	var parent_path = null
	var parent_path_branch_idx
	
	func add_point(id, point):
		point_ids.append(id)
		points.append(point)
		draw_points.append(point)
	
	func insert_draw_point(i, point):
		draw_points.insert(i, point)
	
	func update_draw_point(i, point):
		draw_points[i] = point
	
	func set_parent_branch(p, parent_point_idx):
		parent_path = p
		parent_path_branch_idx = parent_point_idx


var lightning_paths = []
var remenant_weights = []
var astar_grid = AStar2D.new()
var start_id = 0
var end_id = 9
var num_points_to_end = 0


# Setup
func _ready():
	randomize()
	var i = 0
	
	# Create astar grid
	for y in GRID_SIZE.y:
		remenant_weights.append([])
		for x in GRID_SIZE.x:
			var pos = GRID_SCALE * Vector2(x, y) - GRID_SIZE * GRID_SCALE / 2.0
			astar_grid.add_point(i, pos)
			remenant_weights[y].append(0.0)
			i += 1
	
	# Connect grid points
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			i = y * GRID_SIZE.y + x
			if x % int(GRID_SIZE.x) != GRID_SIZE.x - 1:
				astar_grid.connect_points(i, i + 1, true)
			if y % int(GRID_SIZE.y) != GRID_SIZE.y - 1:
				astar_grid.connect_points(i, i + GRID_SIZE.x, true)
	
	for y in GRID_SIZE.y - 1:
		i = y * GRID_SIZE.y + 4
		astar_grid.set_point_disabled(i, true)


# Perform simulation
func simulate():
	lightning_paths.clear()
	for i in NUM_OF_STRIKES:
		strike()
		if i != NUM_OF_STRIKES - 1:
			yield(get_tree().create_timer(TIME_BETWEEN_STRIKES), "timeout")
	emit_signal("simulation_completed")


# Perform a single lightning strike
func strike():
	# Make sure random number generation is seeded
	randomize()
	
	# Reset weights
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			remenant_weights[y][x] = 0.0
	
	# Determine weights using last strike
	for path in lightning_paths:
		for p_idx in path.point_ids:
			var x = int(p_idx % int(GRID_SIZE.x))
			var y = int(p_idx / GRID_SIZE.y)
			if path.tier == 1:
				remenant_weights[y][x] = PRIMARY_REMENANT_WEIGHT
			elif remenant_weights[y][x] == 0:
				remenant_weights[y][x] = SECONDARY_REMENANT_WEIGHT
	lightning_paths.clear()
	
	# Set random weights with influence from remenant weights
	var i = 0
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var w = rand_range(CELL_WEIGHT_RANGE.x, CELL_WEIGHT_RANGE.y)
			w = clamp(w - remenant_weights[y][x], CELL_WEIGHT_RANGE.x, CELL_WEIGHT_RANGE.y)
			astar_grid.set_point_weight_scale(i, w)
			i += 1
	
	# Calculcate length of primary path to determine how close to end
	num_points_to_end = astar_grid.get_id_path(start_id, end_id).size()
	
	# Create primary lightning path (which may branch)
	create_lightning(start_id, end_id)
	update()  # Draw


# Create lightning path
# May recursively branch
func create_lightning(from, to, parent_branch=null, branch_point_idx=null):
	var lightning = LightningPath.new()
	lightning_paths.append(lightning)
	
	# Setup branching
	if parent_branch:
		lightning.tier = parent_branch.tier * 2
		var branch_point_id = parent_branch.point_ids[branch_point_idx]
		lightning.add_point(branch_point_id, astar_grid.get_point_position(branch_point_id))
		lightning.set_parent_branch(parent_branch, branch_point_idx)
	
	var astar_path = astar_grid.get_id_path(from, to)
	
	# Go throw path, possibly branching along the way
	for i in astar_path.size():
		var p_id = astar_path[i]
		lightning.add_point(p_id, astar_grid.get_point_position(p_id))
		
		# Don't branch at end
		if i == astar_path.size() - 1:
			continue
		
		# Determine branch chance using the max branch chance and the branch chance curve
		var ratio = clamp(1.0 - (astar_path.size() - i) / float(num_points_to_end), 0.0, 1.0)
		var branch_chance = MAX_BRANCH_CHANCE * BRANCH_CHANCE_CURVE.interpolate(ratio)
		
		# Determine if a branch occurs
		if randf() < branch_chance:
			# Get adjacent cells
			var neighbors = astar_grid.get_point_connections(p_id)
			if neighbors.size() < 2:
				continue
			
			# Find a neighbor to branch to
			for neighbor in neighbors:
				if astar_grid.is_point_disabled(neighbor):
					continue
				var branch_path = astar_grid.get_id_path(neighbor, to)
				if branch_path.size() < 2:
					continue
				if branch_path[0] == astar_path[i+1]:
					continue
				if branch_path[1] == p_id:
					continue
				if i > 1 and branch_path[0] == astar_path[i-1]:
					continue
				create_lightning(neighbor, to, lightning, i)
				break

func _draw():
	# Draw grid
	for point_index in astar_grid.get_points():
		if astar_grid.is_point_disabled(point_index):
			continue
		var pos = astar_grid.get_point_position(point_index)
		draw_circle(pos, 1.0, GRID_POINTS_COLOR)
	
	# Update draw points
	for lightning in lightning_paths:
		# Add intermediate points
		var p_idx = 0
		while p_idx < lightning.draw_points.size() - 1:
			var p1 = lightning.draw_points[p_idx]
			var p3 = lightning.draw_points[p_idx+1]
			if lightning.tier > 1:
				seed(int(p1.x) + int(p1.y))
			var p2 = p1 + (p3-p1)/2.0 + GRID_SCALE * tan(rand_range(-SEGMENT_MAX_ANGLE, SEGMENT_MAX_ANGLE)) * (p3-p1).tangent().normalized()
			lightning.insert_draw_point(p_idx + 1, p2)
			p_idx += 2
		
		# Update branch start position, as they get adjusted in previous iterations
		if lightning.parent_path:
			lightning.update_draw_point(0, lightning.parent_path.draw_points[lightning.parent_path_branch_idx * 2])
		
		# Update original points using new intermediate points
		p_idx = 2
		while p_idx < lightning.draw_points.size() - 1:
			var p1 = lightning.draw_points[p_idx-1]
			var p3 = lightning.draw_points[p_idx+1]
			var p2 = p1 + (p3-p1)/2.0 + GRID_SCALE * tan(rand_range(-SEGMENT_MAX_ANGLE, SEGMENT_MAX_ANGLE)) * (p3-p1).tangent().normalized()
			lightning.update_draw_point(p_idx, p2)
			p_idx += 2
	
	# Draw lightning
	var primary_color = PRIMARY_LINE_COLOR
	var secondary_color = SECONDARY_LINE_COLOR
	for lightning in lightning_paths:
		# Alpha is dependent on how many times it had branched
		primary_color.a = PRIMARY_LINE_COLOR.a / lightning.tier
		secondary_color.a = SECONDARY_LINE_COLOR.a / lightning.tier
		
		# Draw faint secondary line and brighter primary line
		draw_polyline(lightning.draw_points, primary_color, PRIMARY_LINE_WIDTH)
		draw_polyline(lightning.draw_points, secondary_color, SECONDARY_LINE_WIDTH)
