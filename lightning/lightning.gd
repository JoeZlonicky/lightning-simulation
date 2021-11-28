extends Sprite


signal path_not_found
signal strike_completed

export (float) var MAX_BRANCH_CHANCE = 0.75
export (float) var TIME_BETWEEN_STRIKES = 0.05 setget set_time_between_strikes
export (Curve) var BRANCH_CHANCE_CURVE
export (Vector2) var CELL_WEIGHT_RANGE = Vector2(1.0, 10.0)
export (Vector2) var STRENGTH_RANGE = Vector2(0.3, 1.0)

const GRID_SIZE = Vector2(10, 10)
const GRID_SCALE = 40.0
const GRID_POINTS_COLOR = Color(1.0, 1.0, 1.0, 0.6)
const GRID_DISABLED_POINTS_COLOR = Color(1.0, 1.0, 1.0, 0.1)
const PRIMARY_LINE_WIDTH = 3.0
const SECONDARY_LINE_WIDTH = 24.0
const PRIMARY_LINE_COLOR = Color("ffc2f1")
const SECONDARY_LINE_COLOR = Color("ffc2f1") / 4.0
const SEGMENT_MAX_ANGLE = 16.0 / 180.0 * PI
const PRIMARY_REMENANT_WEIGHT = 3.0
const SECONDARY_REMENANT_WEIGHT = 2.0


class LightningPath:
	var points = PoolVector2Array()
	var point_ids = PoolIntArray()
	var draw_points = PoolVector2Array()
	var tier = 1
	var strength = 1.0
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
	
	# Update strike timer to default
	$StrikeTimer.wait_time = TIME_BETWEEN_STRIKES


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var nearest_id = astar_grid.get_closest_point(event.position - position, true)
		var nearest_point = astar_grid.get_point_position(nearest_id)
		if (nearest_point - (event.position - position)).length() > 10.0:
			return
		
		if event.button_index == BUTTON_LEFT:
			if astar_grid.is_point_disabled(nearest_id) or nearest_id == end_id:
				return
			start_id = nearest_id
			update()
		elif event.button_index == BUTTON_MIDDLE:
			if nearest_id == start_id or nearest_id == end_id:
				return
			astar_grid.set_point_disabled(nearest_id, !astar_grid.is_point_disabled(nearest_id))
			update()
		elif event.button_index == BUTTON_RIGHT:
			if astar_grid.is_point_disabled(nearest_id) or nearest_id == start_id:
				return
			end_id = nearest_id
			update()


# Perform simulation
func start_simulation():
	lightning_paths.clear()
	strike()
	$StrikeTimer.start()


# Stop simulation
func end_simulation():
	$StrikeTimer.stop()


func single_strike():
	lightning_paths.clear()
	strike()

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
	
	randomize()
	
	# Calculcate length of primary path to determine how close to end
	num_points_to_end = astar_grid.get_id_path(start_id, end_id).size()
	if num_points_to_end == 0:
		emit_signal("path_not_found")
	
	# Create primary lightning path (which may branch)
	create_lightning(start_id, end_id)
	update_lightning_drawing()
	update()  # Draw
	
	if num_points_to_end > 0:
		emit_signal("strike_completed")


# Create lightning path
# May recursively branch
func create_lightning(from, to, parent_branch=null, branch_point_idx=null):
	var lightning = LightningPath.new()
	lightning.strength = rand_range(STRENGTH_RANGE.x, STRENGTH_RANGE.y)
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


func update_lightning_drawing():
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


func _draw():
	# Draw grid
	for point_index in astar_grid.get_points():
		var pos = astar_grid.get_point_position(point_index)
		if point_index == start_id:
			draw_circle(pos, 4.0, Color(0.0, 1.0, 0.0, 0.2))
		if point_index == end_id:
			draw_circle(pos, 4.0, Color(1.0, 0.0, 0.0, 0.2))
		if astar_grid.is_point_disabled(point_index):
			draw_circle(pos, 1.0, GRID_DISABLED_POINTS_COLOR)
		else:
			draw_circle(pos, 1.0, GRID_POINTS_COLOR)
	
	# Draw lightning
	var primary_color = PRIMARY_LINE_COLOR
	var secondary_color = SECONDARY_LINE_COLOR
	for lightning in lightning_paths:
		if not lightning.draw_points:
			continue

		# Alpha is dependent on how many times it had branched
		primary_color.a = lightning.strength * PRIMARY_LINE_COLOR.a / lightning.tier
		secondary_color.a = lightning.strength * SECONDARY_LINE_COLOR.a / lightning.tier
		
		# Draw faint secondary line and brighter primary line
		draw_polyline(lightning.draw_points, primary_color, PRIMARY_LINE_WIDTH * lightning.strength)
		draw_polyline(lightning.draw_points, secondary_color, SECONDARY_LINE_WIDTH * lightning.strength)


func _on_StrikeTimer_timeout():
	strike()


func set_time_between_strikes(new_time):
	TIME_BETWEEN_STRIKES = new_time
	$StrikeTimer.wait_time = new_time
