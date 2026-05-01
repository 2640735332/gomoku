# game_state.gd
# Manages the 15x15 Gomoku board state, move history, and win detection
class_name GameState
extends RefCounted

const BOARD_SIZE = 15
const EMPTY = 0
const BLACK = 1  # First player
const WHITE = 2  # Second player

# Board represented as 2D array: board[row][col]
# 0 = empty, 1 = black, 2 = white
var board: Array
var current_player: int = BLACK
var move_history: Array  # Array of {"row": int, "col": int, "player": int}
var move_count: int = 0
var game_over: bool = false
var winner: int = EMPTY
var win_positions: Array = []  # Array of Vector2i for the winning line

func _init():
	reset()

func reset():
	board = []
	for r in range(BOARD_SIZE):
		var row = []
		for c in range(BOARD_SIZE):
			row.append(EMPTY)
		board.append(row)
	current_player = BLACK
	move_history.clear()
	move_count = 0
	game_over = false
	winner = EMPTY
	win_positions.clear()

func place_stone(row: int, col: int) -> bool:
	if game_over:
		return false
	if row < 0 or row >= BOARD_SIZE or col < 0 or col >= BOARD_SIZE:
		return false
	if board[row][col] != EMPTY:
		return false
	
	board[row][col] = current_player
	move_history.append({"row": row, "col": col, "player": current_player})
	move_count += 1
	
	# Check for win
	var result = check_win_at(row, col, current_player)
	if result.has("won") and result.won:
		game_over = true
		winner = current_player
		win_positions = result.positions
		return true
	
	# Check for draw
	if move_count >= BOARD_SIZE * BOARD_SIZE:
		game_over = true
		winner = EMPTY
		return true
	
	# Switch player
	current_player = WHITE if current_player == BLACK else BLACK
	return true

func undo_last_move() -> bool:
	if move_history.is_empty():
		return false
	if game_over:
		game_over = false
		winner = EMPTY
		win_positions.clear()
	
	var last = move_history.pop_back()
	board[last.row][last.col] = EMPTY
	move_count -= 1
	current_player = last.player
	return true

func check_win_at(row: int, col: int, player: int) -> Dictionary:
	# Directions: horizontal, vertical, diagonal down-right, diagonal up-right
	var directions = [
		Vector2i(0, 1),   # horizontal
		Vector2i(1, 0),   # vertical
		Vector2i(1, 1),   # diagonal \
		Vector2i(-1, 1),  # diagonal /
	]
	
	for dir in directions:
		var positions = [Vector2i(row, col)]
		
		# Check in positive direction
		var r = row + dir.x
		var c = col + dir.y
		while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE and board[r][c] == player:
			positions.append(Vector2i(r, c))
			r += dir.x
			c += dir.y
		
		# Check in negative direction
		r = row - dir.x
		c = col - dir.y
		while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE and board[r][c] == player:
			positions.append(Vector2i(r, c))
			r -= dir.x
			c -= dir.y
		
		if positions.size() >= 5:
			return {"won": true, "positions": positions}
	
	return {"won": false, "positions": []}

func get_cell(row: int, col: int) -> int:
	if row < 0 or row >= BOARD_SIZE or col < 0 or col >= BOARD_SIZE:
		return -1
	return board[row][col]
