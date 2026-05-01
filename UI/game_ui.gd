# game_ui.gd
# Linear-inspired dark UI for Gomoku
extends Control

signal undo_pressed()
signal reset_pressed()

var game_state: GameState

@onready var current_turn_label: Label = %CurrentTurnLabel
@onready var turn_indicator: Control = %TurnIndicator
@onready var move_count_label: Label = %MoveCountLabel
@onready var undo_button: Button = %UndoButton
@onready var reset_button: Button = %ResetButton
@onready var status_label: Label = %StatusLabel
@onready var victory_panel: Panel = %VictoryPanel
@onready var victory_label: Label = %VictoryLabel
@onready var victory_subtitle: Label = %VictorySubtitle
@onready var play_again_button: Button = %PlayAgainButton
@onready var undo_container: Control = %UndoContainer

func _ready():
	update_ui()

func update_ui():
	if not game_state:
		return
	
	# Update turn indicator
	if game_state.game_over:
		if game_state.winner == GameState.EMPTY:
			current_turn_label.text = "DRAW"
			status_label.text = "Game ended in a draw"
		elif game_state.winner == GameState.BLACK:
			current_turn_label.text = "BLACK WINS!"
			status_label.text = "Five in a row!"
		elif game_state.winner == GameState.WHITE:
			current_turn_label.text = "WHITE WINS!"
			status_label.text = "Five in a row!"
		
		turn_indicator.modulate = Color("#10b981")  # Green for victory
		move_count_label.text = "Moves: " + str(game_state.move_count)
		undo_button.disabled = true
		undo_button.modulate = Color("#62666d", 0.5)
		
		if game_state.winner != GameState.EMPTY:
			victory_panel.visible = true
			victory_label.text = "Black Wins!" if game_state.winner == GameState.BLACK else "White Wins!"
			victory_subtitle.text = "5 in a row detected"
		
		return
	
	# Normal game state
	victory_panel.visible = false
	
	var player_name = "Black" if game_state.current_player == GameState.BLACK else "White"
	current_turn_label.text = player_name + "'s Turn"
	turn_indicator.modulate = Color("#1a1a1a") if game_state.current_player == GameState.BLACK else Color("#e8e8e8")
	
	move_count_label.text = "Move " + str(game_state.move_count + 1) + " / " + str(GameState.BOARD_SIZE * GameState.BOARD_SIZE)
	
	var has_moves = game_state.move_count > 0
	undo_button.disabled = not has_moves
	undo_button.modulate = Color("#d0d6e0", 1.0 if has_moves else 0.5)
	status_label.text = "Place your stone"

func _on_undo_pressed():
	undo_pressed.emit()

func _on_reset_pressed():
	reset_pressed.emit()

func _on_play_again_pressed():
	victory_panel.visible = false
	reset_pressed.emit()
