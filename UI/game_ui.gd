# game_ui.gd
# 五子棋 UI - 暗色圆角风格，支持中文
extends Control

signal undo_pressed()
signal reset_pressed()
signal exit_pressed()

var game_state: GameState

@onready var current_turn_label: Label = %CurrentTurnLabel
@onready var turn_indicator: ColorRect = %TurnIndicator
@onready var move_count_label: Label = %MoveCountLabel
@onready var undo_button: Button = %UndoButton
@onready var reset_button: Button = %ResetButton
@onready var exit_button: Button = %ExitButton
@onready var status_label: Label = %StatusLabel
@onready var victory_panel: ColorRect = %VictoryPanel
@onready var victory_label: Label = %VictoryLabel
@onready var victory_subtitle: Label = %VictorySubtitle
@onready var play_again_button: Button = %PlayAgainButton

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

func update_ui():
	if not game_state:
		return

	if game_state.game_over:
		if game_state.winner == GameState.EMPTY:
			current_turn_label.text = "平局"
			status_label.text = "棋盘已满，不分胜负"
		elif game_state.winner == GameState.BLACK:
			current_turn_label.text = "黑方获胜！"
			status_label.text = "五子连珠！"
		elif game_state.winner == GameState.WHITE:
			current_turn_label.text = "白方获胜！"
			status_label.text = "五子连珠！"

		turn_indicator.color = Color(0.063, 0.725, 0.506, 1.0)  # Green
		move_count_label.text = "步数: " + str(game_state.move_count)
		undo_button.disabled = true
		undo_button.modulate = Color(0.384, 0.400, 0.427, 0.4)

		if game_state.winner != GameState.EMPTY:
			victory_panel.visible = true
			victory_label.text = "黑方胜利！" if game_state.winner == GameState.BLACK else "白方胜利！"
			victory_subtitle.text = "五子连珠，恭喜！"
		return

	# 正常游戏状态
	victory_panel.visible = false

	var player_name = "黑方" if game_state.current_player == GameState.BLACK else "白方"
	current_turn_label.text = player_name + "落子"
	turn_indicator.color = Color(0.102, 0.102, 0.102, 1.0) if game_state.current_player == GameState.BLACK else Color(0.91, 0.91, 0.91, 1.0)

	move_count_label.text = "第 " + str(game_state.move_count + 1) + " 手"

	var has_moves = game_state.move_count > 0
	undo_button.disabled = not has_moves
	undo_button.modulate = Color(0.816, 0.839, 0.878, 1.0 if has_moves else 0.4)
	status_label.text = "请落子"

func _on_undo_pressed():
	undo_pressed.emit()

func _on_reset_pressed():
	reset_pressed.emit()

func _on_play_again_pressed():
	reset_pressed.emit()

func _on_exit_pressed():
	exit_pressed.emit()
