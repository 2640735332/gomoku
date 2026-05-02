# game_ui.gd
# 五子棋 UI — 毛玻璃深色风格，子数统计，胜利动画
extends Control

signal undo_pressed()
signal reset_pressed()
signal exit_pressed()

var game_state: GameState

@onready var glass_bar: ColorRect = %GlassBar
@onready var status_text: Label = %StatusText
@onready var turn_dot: ColorRect = %TurnDot
@onready var undo_button: Button = %UndoButton
@onready var reset_button: Button = %ResetButton
@onready var exit_button: Button = %ExitButton
@onready var status_label: Label = %StatusLabel
@onready var move_history: Label = %MoveHistory
@onready var black_label: Label = %BlackLabel
@onready var black_count: Label = %BlackCount
@onready var white_label: Label = %WhiteLabel
@onready var white_count: Label = %WhiteCount
@onready var victory_panel: ColorRect = %VictoryPanel
@onready var victory_label: Label = %VictoryLabel
@onready var victory_subtitle: Label = %VictorySubtitle
@onready var play_again_button: Button = %PlayAgainButton

var _victory_tween: Tween = null
var _victory_time: float = 0.0

func _ready():
	update_ui()
	if undo_button:
		undo_button.pressed.connect(_on_undo_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _process(delta):
	# Animate victory panel pulsing
	if victory_panel.visible:
		_victory_time += delta
		var pulse = 0.85 + 0.15 * sin(_victory_time * 2.0)
		victory_label.modulate = Color(1, 1, 1, pulse)

func update_ui():
	if not game_state:
		return
	
	# Stone counts
	var black_stones = 0
	var white_stones = 0
	for r in range(15):
		for c in range(15):
			match game_state.board[r][c]:
				GameState.BLACK: black_stones += 1
				GameState.WHITE: white_stones += 1
	black_count.text = str(black_stones) + " 子"
	white_count.text = str(white_stones) + " 子"
	
	# Last move display
	if game_state.move_count > 0 and game_state.move_history.size() > 0:
		var last = game_state.move_history.back()
		move_history.text = "最近落子: (" + str(last.row) + "," + str(last.col) + ")"
	else:
		move_history.text = ""
	
	if game_state.game_over:
		if game_state.winner == GameState.EMPTY:
			status_text.text = "平局"
			status_label.text = "棋盘已满，不分胜负"
		elif game_state.winner == GameState.BLACK:
			status_text.text = "黑方获胜！"
			status_label.text = "五子连珠！"
		elif game_state.winner == GameState.WHITE:
			status_text.text = "白方获胜！"
			status_label.text = "五子连珠！"
		
		turn_dot.color = Color(0.063, 0.725, 0.506, 1.0)
		undo_button.disabled = true
		undo_button.modulate = Color(0.384, 0.400, 0.427, 0.4)
		
		if game_state.winner != GameState.EMPTY:
			_show_victory()
		return
	
	# Normal game state
	_hide_victory()
	
	var player_name = "黑方" if game_state.current_player == GameState.BLACK else "白方"
	status_text.text = player_name + "落子 · 第 " + str(game_state.move_count + 1) + " 手"
	turn_dot.color = Color(0.102, 0.102, 0.102, 1.0) if game_state.current_player == GameState.BLACK else Color(0.91, 0.91, 0.91, 1.0)
	
	var has_moves = game_state.move_count > 0
	undo_button.disabled = not has_moves
	undo_button.modulate = Color(0.769, 0.792, 0.886, 1.0 if has_moves else 0.4)
	status_label.text = "请落子"

func _show_victory():
	victory_panel.visible = true
	victory_label.visible = true
	victory_subtitle.visible = true
	play_again_button.visible = true
	
	if game_state.winner == GameState.BLACK:
		victory_label.text = "黑方胜利！"
	elif game_state.winner == GameState.WHITE:
		victory_label.text = "白方胜利！"
	victory_subtitle.text = "五子连珠，恭喜！"
	
	# Scale-up animation
	victory_panel.scale = Vector2(0.8, 0.8)
	if _victory_tween and _victory_tween.is_valid():
		_victory_tween.kill()
	_victory_tween = create_tween()
	_victory_tween.tween_property(victory_panel, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_victory_time = 0.0

func _hide_victory():
	victory_panel.visible = false
	victory_label.visible = false
	victory_subtitle.visible = false
	play_again_button.visible = false
	if _victory_tween and _victory_tween.is_valid():
		_victory_tween.kill()
	_victory_tween = null

func _on_undo_pressed():
	undo_pressed.emit()

func _on_reset_pressed():
	reset_pressed.emit()

func _on_play_again_pressed():
	reset_pressed.emit()

func _on_exit_pressed():
	exit_pressed.emit()
