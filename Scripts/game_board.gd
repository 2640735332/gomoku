# game_board.gd
# Renders the 15x15 Gomoku board with all visual styling (Linear-inspired dark theme)
extends Control

signal cell_clicked(row, col)

const BOARD_SIZE = 15
const GRID_SIZE = 38
const BOARD_OFFSET = 40
const CELL_SIZE = 38
const BOARD_WIDTH = (BOARD_SIZE - 1) * GRID_SIZE
const BOARD_HEIGHT = (BOARD_SIZE - 1) * GRID_SIZE

# Colors - Linear inspired dark theme
const COLOR_BG = Color("#08090a")
const COLOR_BOARD_BG = Color("#0f1011")
const COLOR_GRID = Color("#23252a")
const COLOR_GRID_STAR = Color("#5e6ad2")
const COLOR_HOVER = Color("#7170ff")
const COLOR_BLACK = Color("#1a1a1a")
const COLOR_BLACK_HIGHLIGHT = Color("#2a2a2a")
const COLOR_WHITE = Color("#e8e8e8")
const COLOR_WHITE_HIGHLIGHT = Color("#f5f5f5")
const COLOR_WIN_LINE = Color("#10b981")
const COLOR_COORD = Color("#62666d")
const COLOR_LAST_MOVE = Color("#7170ff")

var game_state: GameState
var hover_cell: Vector2i = Vector2i(-1, -1)
var last_move: Vector2i = Vector2i(-1, -1)

# Star points (standard Gomoku star positions)
const STAR_POINTS = [
	Vector2i(3, 3), Vector2i(3, 7), Vector2i(3, 11),
	Vector2i(7, 3), Vector2i(7, 7), Vector2i(7, 11),
	Vector2i(11, 3), Vector2i(11, 7), Vector2i(11, 11)
]

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(BOARD_WIDTH + BOARD_OFFSET * 2, BOARD_HEIGHT + BOARD_OFFSET * 2)

func _draw():
	draw_board_bg()
	draw_grid()
	draw_stars()
	draw_coordinates()
	draw_stones()
	if not game_state.game_over and hover_cell.x >= 0:
		draw_hover()
	if last_move.x >= 0:
		draw_last_marker()
	if game_state.win_positions.size() > 0:
		draw_win_highlight()

func draw_board_bg():
	var rect = Rect2(0, 0, BOARD_WIDTH + BOARD_OFFSET * 2, BOARD_HEIGHT + BOARD_OFFSET * 2)
	draw_rect(rect, COLOR_BG, true)
	
	var board_rect = Rect2(
		BOARD_OFFSET - 16, BOARD_OFFSET - 16,
		BOARD_WIDTH + 32, BOARD_HEIGHT + 32
	)
	draw_rect(board_rect, COLOR_BOARD_BG, true)
	
	# Subtle border around board
	var border_color = Color("#23252a")
	draw_rect(board_rect, border_color, false, 1.0)

func draw_grid():
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	
	for i in range(BOARD_SIZE):
		# Horizontal line
		var h_start = board_start + Vector2(0, i * GRID_SIZE)
		var h_end = board_start + Vector2(BOARD_WIDTH, i * GRID_SIZE)
		var h_width = 1.5 if i == 0 or i == BOARD_SIZE - 1 else 1.0
		draw_line(h_start, h_end, COLOR_GRID, h_width)
		
		# Vertical line
		var v_start = board_start + Vector2(i * GRID_SIZE, 0)
		var v_end = board_start + Vector2(i * GRID_SIZE, BOARD_HEIGHT)
		var v_width = 1.5 if i == 0 or i == BOARD_SIZE - 1 else 1.0
		draw_line(v_start, v_end, COLOR_GRID, v_width)

func draw_stars():
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	for sp in STAR_POINTS:
		var pos = board_start + Vector2(sp.x * GRID_SIZE, sp.y * GRID_SIZE)
		draw_circle(pos, 3.0, COLOR_GRID_STAR)

func draw_coordinates():
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	
	# Column labels (A-O)
	for i in range(BOARD_SIZE):
		var pos = Vector2(
			board_start.x + i * GRID_SIZE,
			8
		)
		var label = char(65 + i)
		draw_string(
			ThemeDB.fallback_font,
			pos,
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			10,
			COLOR_COORD
		)
		
		# Row labels (15-1)
		var row_pos = Vector2(
			5,
			board_start.y + i * GRID_SIZE + 4
		)
		draw_string(
			ThemeDB.fallback_font,
			row_pos,
			str(BOARD_SIZE - i),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			COLOR_COORD
		)
		
		# Right column label
		var right_pos = Vector2(
			board_start.x + BOARD_WIDTH + 5,
			board_start.y + i * GRID_SIZE + 4
		)
		draw_string(
			ThemeDB.fallback_font,
			right_pos,
			str(BOARD_SIZE - i),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			COLOR_COORD
		)
		
		# Bottom row label
		var bottom_pos = Vector2(
			board_start.x + i * GRID_SIZE,
			board_start.y + BOARD_HEIGHT + 16
		)
		draw_string(
			ThemeDB.fallback_font,
			bottom_pos,
			char(65 + i),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			10,
			COLOR_COORD
		)

func draw_stones():
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			var cell = game_state.board[r][c]
			if cell == GameState.EMPTY:
				continue
			
			var center = board_start + Vector2(c * GRID_SIZE, r * GRID_SIZE)
			var is_win = false
			if game_state.win_positions.size() > 0:
				for wp in game_state.win_positions:
					if wp.x == r and wp.y == c:
						is_win = true
						break
			
			_draw_stone(center, cell, is_win)

func _draw_stone(center: Vector2, player: int, is_win: bool):
	var radius = 16.0
	var glow_size = 2.0
	
	if player == GameState.BLACK:
		# Shadow
		draw_circle(center + Vector2(1, 1), radius, Color("#000000", 0.3))
		# Main body
		draw_circle(center, radius, COLOR_BLACK)
		# Highlight (top-left reflection)
		draw_circle(center + Vector2(-4, -4), radius * 0.4, Color("#333333", 0.6))
		# Gradient overlay (darker at bottom-right)
		var rect = Rect2(center.x - radius, center.y - radius, radius * 2, radius * 2)
		draw_circle(center, radius, Color("#000000", 0.15))
	else:
		# Shadow
		draw_circle(center + Vector2(1, 1), radius, Color("#000000", 0.2))
		# Main body
		draw_circle(center, radius, COLOR_WHITE)
		# Inner shadow (slightly darker at bottom-right)
		draw_circle(center + Vector2(2, 2), radius * 0.8, Color("#c0c0c0", 0.3))
		# Highlight
		draw_circle(center + Vector2(-4, -4), radius * 0.5, Color("#ffffff", 0.5))
		# Outer ring for definition
		draw_circle(center, radius, Color("#aaaaaa", 0.3), false, 0.5)
	
	# Win glow
	if is_win:
		draw_circle(center, radius + 3, COLOR_WIN_LINE, false, 2.0)
		draw_circle(center, radius + 6, Color("#10b981", 0.2))

func draw_hover():
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	var center = board_start + Vector2(hover_cell.y * GRID_SIZE, hover_cell.x * GRID_SIZE)
	
	var color = COLOR_BLACK_HIGHLIGHT if game_state.current_player == GameState.BLACK else COLOR_WHITE_HIGHLIGHT
	draw_circle(center, 16.0, Color(color, 0.3))
	draw_circle(center, 16.0, COLOR_HOVER, false, 1.0)

func draw_last_marker():
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	var center = board_start + Vector2(last_move.y * GRID_SIZE, last_move.x * GRID_SIZE)
	draw_circle(center, 4.0, COLOR_LAST_MOVE)

func draw_win_highlight():
	if game_state.win_positions.size() < 5:
		return
	
	# Draw connecting line through winning positions
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	var sorted = game_state.win_positions.duplicate()
	sorted.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	
	var points = []
	for pos in sorted:
		points.append(board_start + Vector2(pos.y * GRID_SIZE, pos.x * GRID_SIZE))
	
	if points.size() >= 2:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color("#10b981", 0.5), 4.0)

func cell_at(pos: Vector2) -> Vector2i:
	var board_start = Vector2(BOARD_OFFSET, BOARD_OFFSET)
	var local = pos - board_start
	var col = round(local.x / GRID_SIZE)
	var row = round(local.y / GRID_SIZE)
	
	if row < 0 or row >= BOARD_SIZE or col < 0 or col >= BOARD_SIZE:
		return Vector2i(-1, -1)
	
	# Check if close enough to intersection (within half grid)
	var exact = Vector2(col * GRID_SIZE, row * GRID_SIZE)
	var dist = (local - exact).length()
	if dist > GRID_SIZE * 0.45:
		return Vector2i(-1, -1)
	
	return Vector2i(row, col)

func _gui_input(event):
	if game_state.game_over:
		return
	
	if event is InputEventMouseMotion:
		var cell = cell_at(event.position)
		if cell != hover_cell:
			hover_cell = cell
			queue_redraw()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell = cell_at(event.position)
		if cell.x >= 0 and cell.y >= 0:
			cell_clicked.emit(cell.x, cell.y)

func sync_state():
	queue_redraw()
