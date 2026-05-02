# main.gd
# Main game controller - connects game state, board, and UI
extends Control

var game_state: GameState
var board_pos: Vector2

@onready var board: Control = %GameBoard
@onready var ui: Control = %GameUI

func _ready():
	game_state = GameState.new()
	
	if board:
		board.game_state = game_state
		board.cell_clicked.connect(_on_cell_clicked)
	
	if ui:
		ui.game_state = game_state
		ui.undo_pressed.connect(_on_undo)
		ui.reset_pressed.connect(_on_reset)
	
	_refresh()

func _on_cell_clicked(row: int, col: int):
	var result = game_state.place_stone(row, col)
	if result:
		if game_state.game_over:
			board.last_move = Vector2i(row, col)
		else:
			board.last_move = Vector2i(row, col)
		_refresh()

func _on_undo():
	game_state.undo_last_move()
	if game_state.move_count > 0:
		var last = game_state.move_history.back()
		board.last_move = Vector2i(last.row, last.col)
	else:
		board.last_move = Vector2i(-1, -1)
	_refresh()

func _on_reset():
	game_state.reset()
	board.last_move = Vector2i(-1, -1)
	board.hover_cell = Vector2i(-1, -1)
	_refresh()

func _refresh():
	board.sync_state()
	ui.update_ui()
	
	# Update move history UI if applicable
	if has_node("MoveHistory"):
		_update_history()

func _update_history():
	# Optional: display last few moves
	pass
