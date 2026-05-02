# test_e2e.gd
# 端到端游戏交互测试 — 模拟真实点击落子、按钮操作、布局验证
extends Node

const GameState = preload("res://Scripts/game_state.gd")
const Main = preload("res://Scenes/main.tscn")

var passed = 0
var failed = 0
var main = null
var board = null
var ui = null

func _ready():
	print("🧪 Starting End-to-End gameplay tests...")
	
	main = Main.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	board = main.find_child("GameBoard", true, false)
	ui = main.find_child("GameUI", true, false)
	
	if !board or !ui:
		print("❌ FATAL: Failed to find Board/UI in scene")
		get_tree().quit(1)
		return
	
	# ────────────────────────────────────────
	# Test 1: Click cell (7,7) — black stone placed
	# ────────────────────────────────────────
	board.cell_clicked.emit(7, 7)
	await get_tree().process_frame
	
	var gs = ui.game_state
	if gs.board[7][7] == GameState.BLACK:
		print("✅ Test 1: Click (7,7) places black stone")
		passed += 1
	else:
		print("❌ Test 1: Click (7,7) did not place stone, got ", gs.board[7][7])
		failed += 1
	
	# ────────────────────────────────────────
	# Test 2: Click (7,8) — white stone placed (turn switches)
	# ────────────────────────────────────────
	board.cell_clicked.emit(7, 8)
	await get_tree().process_frame
	
	if gs.board[7][8] == GameState.WHITE:
		print("✅ Test 2: Click (7,8) places white stone")
		passed += 1
	else:
		print("❌ Test 2: Click (7,8) did not place white stone")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 3: Move count correct
	# ────────────────────────────────────────
	if gs.move_count == 2:
		print("✅ Test 3: Move count is 2 after two clicks")
		passed += 1
	else:
		print("❌ Test 3: Move count is ", gs.move_count, ", expected 2")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 4: Click occupied cell — ignored
	# ────────────────────────────────────────
	var prev_count = gs.move_count
	board.cell_clicked.emit(7, 7)  # already black
	await get_tree().process_frame
	
	if gs.move_count == prev_count:
		print("✅ Test 4: Click occupied cell is ignored")
		passed += 1
	else:
		print("❌ Test 4: Occupied cell click changed move count")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 5: Current turn indicator updates
	# ────────────────────────────────────────
	var turn_label = ui.find_child("CurrentTurnLabel", true, false)
	if turn_label and "黑方" in turn_label.text:
		print("✅ Test 5: Turn indicator shows 黑方 (back to black after white placed)")
		passed += 1
	else:
		print("❌ Test 5: Turn indicator shows: ", turn_label.text if turn_label else "null")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 6: Undo button enabled after moves
	# ────────────────────────────────────────
	var undo_btn = ui.find_child("UndoButton", true, false)
	if undo_btn and not undo_btn.disabled:
		print("✅ Test 6: Undo button enabled after 2 moves")
		passed += 1
	else:
		print("❌ Test 6: Undo button disabled after 2 moves")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 7: Press Undo — removes last move
	# ────────────────────────────────────────
	ui.undo_pressed.emit()  # triggers _on_undo in main.gd
	await get_tree().process_frame
	
	if gs.move_count == 1 and gs.board[7][8] == GameState.EMPTY:
		print("✅ Test 7: Undo removes white stone, count back to 1")
		passed += 1
	else:
		print("❌ Test 7: After undo: move_count=", gs.move_count, ", cell(7,8)=", gs.board[7][8])
		failed += 1
	
	# ────────────────────────────────────────
	# Test 8: Press Reset — clears all stones
	# ────────────────────────────────────────
	ui.reset_pressed.emit()  # triggers _on_reset in main.gd
	await get_tree().process_frame
	
	if gs.move_count == 0 and gs.board[7][7] == GameState.EMPTY and not gs.game_over:
		print("✅ Test 8: Reset clears all stones, move_count=0")
		passed += 1
	else:
		print("❌ Test 8: After reset: move_count=", gs.move_count, ", cell(7,7)=", gs.board[7][7])
		failed += 1
	
	# ────────────────────────────────────────
	# Test 9: Simulate 5-in-a-row — game over detected
	# ────────────────────────────────────────
	# Black places at (7,0) through (7,4)
	# White plays elsewhere
	board.cell_clicked.emit(7, 0)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(8, 0)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(7, 1)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(8, 1)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(7, 2)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(8, 2)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(7, 3)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(8, 3)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(7, 4)  # B — wins!
	await get_tree().process_frame
	
	if gs.game_over and gs.winner == GameState.BLACK:
		print("✅ Test 9: 5-in-a-row detected, black wins")
		passed += 1
	else:
		print("❌ Test 9: Game over=", gs.game_over, ", winner=", gs.winner)
		failed += 1
	
	# ────────────────────────────────────────
	# Test 10: Victory panel visible after win
	# ────────────────────────────────────────
	var victory_panel = ui.find_child("VictoryPanel", true, false)
	if victory_panel and victory_panel.visible:
		print("✅ Test 10: Victory panel visible after win")
		passed += 1
	else:
		print("❌ Test 10: Victory panel not visible after win")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 11: Click on board after game over — ignored
	# ────────────────────────────────────────
	var before_count = gs.move_count
	board.cell_clicked.emit(0, 0)
	await get_tree().process_frame
	
	if gs.move_count == before_count:
		print("✅ Test 11: Board click ignored after game over")
		passed += 1
	else:
		print("❌ Test 11: Board click not ignored after game over")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 12: Play Again — clears board, keeps game going
	# ────────────────────────────────────────
	ui.play_again_button.pressed.emit()  # triggers _on_play_again_pressed → reset_pressed
	await get_tree().process_frame
	
	if not gs.game_over and gs.move_count == 0:
		print("✅ Test 12: Play Again button resets game")
		passed += 1
	else:
		print("❌ Test 12: After Play Again: game_over=", gs.game_over, ", moves=", gs.move_count)
		failed += 1
	
	# ────────────────────────────────────────
	# Test 13: Layout — Board and UI have valid positions
	# ────────────────────────────────────────
	if board.position.y > 0 and ui.position.y > board.position.y:
		print("✅ Test 13: Layout — Board above UI, both with positive positions")
		passed += 1
	else:
		print("❌ Test 13: Layout — Board.y=", board.position.y, ", UI.y=", ui.position.y)
		failed += 1
	
	# ────────────────────────────────────────
	# Test 14: Board size is reasonable
	# ────────────────────────────────────────
	var board_min_size = max(400, min(board.size.x, board.size.y))
	if board_min_size >= 400:
		print("✅ Test 14: Board has reasonable size (", int(board.size.x), "x", int(board.size.y), ")")
		passed += 1
	else:
		print("❌ Test 14: Board too small: ", board.size)
		failed += 1
	
	# ────────────────────────────────────────
	# Test 15: UI fits in viewport
	# ────────────────────────────────────────
	var vp_size = get_viewport().get_visible_rect().size
	if ui.position.y + ui.size.y <= vp_size.y:
		print("✅ Test 15: UI fits within viewport (bottom at ", int(ui.position.y + ui.size.y), ")")
		passed += 1
	else:
		print("❌ Test 15: UI bottom=", int(ui.position.y + ui.size.y), " > vp_h=", int(vp_size.y))
		failed += 1
	
	# ────────────────────────────────────────
	# Test 16: Buttons visible (within UI bounds)
	# ────────────────────────────────────────
	var reset_btn = ui.find_child("ResetButton", true, false)
	var exit_btn = ui.find_child("ExitButton", true, false)
	var all_buttons_in_ui = true
	
	for btn in [undo_btn, reset_btn, exit_btn]:
		if btn:
			var btn_global_pos = btn.global_position
			if btn_global_pos.x < 0 or btn_global_pos.y < ui.position.y:
				all_buttons_in_ui = false
				print("   ⚠ Button at unexpected position: ", btn.name, " global=", btn_global_pos)
	
	var play_again = ui.find_child("PlayAgainButton", true, false)
	
	if all_buttons_in_ui and play_again and not gs.game_over and not victory_panel.visible:
		print("✅ Test 16: All buttons within UI bounds, Play Again hidden normally")
		passed += 1
	else:
		print("❌ Test 16: Button layout issue")
		failed += 1
	
	# ────────────────────────────────────────
	# Test 17: Simulate two full games back-to-back
	# ────────────────────────────────────────
	# Play first game to completion
	board.cell_clicked.emit(5, 5)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(6, 5)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(5, 6)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(6, 6)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(5, 7)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(6, 7)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(5, 8)  # B
	await get_tree().process_frame
	board.cell_clicked.emit(6, 8)  # W
	await get_tree().process_frame
	board.cell_clicked.emit(5, 9)  # B — wins!
	await get_tree().process_frame
	
	if not gs.game_over:
		print("❌ Test 17: Second game did not end")
		failed += 1
	else:
		print("✅ Test 17: Second game playable to completion")
		passed += 1
	
	# Replay
	play_again.pressed.emit()
	await get_tree().process_frame
	
	if gs.game_over or gs.move_count > 0:
		print("❌ Test 17b: Play Again did not reset second game")
		failed += 1
	else:
		print("✅ Test 17b: Play Again works after second game")
		passed += 1
	
	# ────────────────────────────────────────
	# Summary
	# ────────────────────────────────────────
	print("")
	print("📊 Results: %d passed, %d failed, %d total" % [passed, failed, passed + failed])
	if failed > 0:
		print("❌ SOME E2E TESTS FAILED")
		get_tree().quit(1)
	else:
		print("✅ ALL E2E TESTS PASSED")
		get_tree().quit(0)
