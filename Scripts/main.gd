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
		ui.exit_pressed.connect(_on_exit)
	
	# 动态布局：根据 viewport 尺寸调整 Board 和 UI 位置
	_layout_elements()
	
	# 监听大小变化（横竖屏切换）
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	_refresh()

func _layout_elements():
	"""根据当前 viewport 尺寸动态布局 Board 和 UI"""
	var vp_size = get_viewport().get_visible_rect().size
	var vp_w = vp_size.x
	var vp_h = vp_size.y
	
	# UI 高度固定 150px，贴底
	var ui_h = 150
	var ui_top = vp_h - ui_h
	
	if ui:
		# 使用 PRESET_TOP_LEFT 避免与 full_rect 冲突
		ui.anchors_preset = Control.PRESET_TOP_LEFT
		ui.position = Vector2(0, ui_top)
		ui.size = Vector2(vp_w, ui_h)
	
	# Board 在剩余区域居中，正方形
	var available_h = ui_top
	var board_size = min(vp_w - 20, available_h - 20)
	board_size = max(400, min(board_size, 600))
	var board_x = (vp_w - board_size) / 2
	var board_y = (available_h - board_size) / 2
	
	if board:
		board.anchors_preset = Control.PRESET_TOP_LEFT
		board.position = Vector2(board_x, board_y)
		board.size = Vector2(board_size, board_size)

func _on_viewport_size_changed():
	_layout_elements()
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

func _on_exit():
	get_tree().quit()

func _refresh():
	board.sync_state()
	ui.update_ui()
	
	# Update move history UI if applicable
	if has_node("MoveHistory"):
		_update_history()

func _update_history():
	# Optional: display last few moves
	pass
