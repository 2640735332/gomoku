# test_gomoku.gd
# Test runner for Gomoku game
extends Node

const GameState = preload("res://Scripts/game_state.gd")

func _ready():
	print("🧪 Starting Gomoku tests...")
	var passed = 0
	var failed = 0
	
	var state = GameState.new()
	
	# Test 1: Initial state
	if state.board.size() == 15:
		print("✅ Test 1: Board is 15x15")
		passed += 1
	else:
		print("❌ Test 1: Board size mismatch")
		failed += 1
	
	# Test 2: Place a stone
	if state.place_stone(7, 7):
		print("✅ Test 2: Place stone at (7,7)")
		passed += 1
	else:
		print("❌ Test 2: Failed to place stone")
		failed += 1
	
	# Test 3: Cell occupied
	if not state.place_stone(7, 7):
		print("✅ Test 3: Cannot place on occupied cell")
		passed += 1
	else:
		print("❌ Test 3: Placed on occupied cell")
		failed += 1
	
	# Test 4: Player switches
	if state.current_player == GameState.WHITE:
		print("✅ Test 4: Player switched to White")
		passed += 1
	else:
		print("❌ Test 4: Player did not switch")
		failed += 1
	
	# Test 5: Undo
	if state.undo_last_move():
		if state.board[7][7] == GameState.EMPTY:
			print("✅ Test 5: Undo removes stone")
			passed += 1
		else:
			print("❌ Test 5: Undo did not clear cell")
			failed += 1
	else:
		print("❌ Test 5: Undo failed")
		failed += 1
	
	# Test 6: Horizontal win detection + win positions
	state.reset()
	state.place_stone(7, 0)  # Black
	state.place_stone(0, 0)  # White
	state.place_stone(7, 1)  # Black
	state.place_stone(0, 1)  # White
	state.place_stone(7, 2)  # Black
	state.place_stone(0, 2)  # White
	state.place_stone(7, 3)  # Black
	state.place_stone(0, 3)  # White
	state.place_stone(7, 4)  # Black - wins!
	
	if state.game_over and state.winner == GameState.BLACK:
		print("✅ Test 6: Horizontal win detection")
		passed += 1
	else:
		print("❌ Test 6: Win not detected")
		failed += 1
	
	if state.win_positions.size() >= 5:
		print("✅ Test 7: Win positions tracked (%d positions)" % state.win_positions.size())
		passed += 1
	else:
		print("❌ Test 7: Win positions not tracked")
		failed += 1
	
	# Test 8: Vertical win detection
	state.reset()
	state.place_stone(3, 5)  # Black
	state.place_stone(0, 0)  # White
	state.place_stone(4, 5)  # Black
	state.place_stone(0, 1)  # White
	state.place_stone(5, 5)  # Black
	state.place_stone(0, 2)  # White
	state.place_stone(6, 5)  # Black
	state.place_stone(0, 3)  # White
	state.place_stone(7, 5)  # Black - wins vertically!
	
	if state.game_over and state.winner == GameState.BLACK:
		print("✅ Test 8: Vertical win detection")
		passed += 1
	else:
		print("❌ Test 8: Vertical win not detected")
		failed += 1
	
	# Test 9: Diagonal win detection
	state.reset()
	state.place_stone(0, 0)  # Black
	state.place_stone(0, 1)  # White
	state.place_stone(1, 1)  # Black
	state.place_stone(0, 2)  # White
	state.place_stone(2, 2)  # Black
	state.place_stone(0, 3)  # White
	state.place_stone(3, 3)  # Black
	state.place_stone(0, 4)  # White
	state.place_stone(4, 4)  # Black - wins diagonally!
	
	if state.game_over and state.winner == GameState.BLACK:
		print("✅ Test 9: Diagonal win detection")
		passed += 1
	else:
		print("❌ Test 9: Diagonal win not detected")
		failed += 1
	
	# Test 10: Anti-diagonal win detection
	state.reset()
	state.place_stone(0, 4)  # Black
	state.place_stone(0, 0)  # White
	state.place_stone(1, 3)  # Black
	state.place_stone(0, 1)  # White
	state.place_stone(2, 2)  # Black
	state.place_stone(0, 2)  # White
	state.place_stone(3, 1)  # Black
	state.place_stone(0, 3)  # White
	state.place_stone(4, 0)  # Black - wins anti-diagonally!
	
	if state.game_over and state.winner == GameState.BLACK:
		print("✅ Test 10: Anti-diagonal win detection")
		passed += 1
	else:
		print("❌ Test 10: Anti-diagonal win not detected")
		failed += 1
	
	# Test 11: No false win
	state.reset()
	state.place_stone(7, 0)  # Black
	state.place_stone(7, 1)  # White
	state.place_stone(7, 2)  # Black
	state.place_stone(7, 3)  # White
	state.place_stone(7, 4)  # Black - only 3, no win
	state.place_stone(0, 0)  # White
	state.place_stone(8, 0)  # Black
	state.place_stone(0, 1)  # White
	state.place_stone(9, 0)  # Black
	
	if not state.game_over:
		print("✅ Test 11: No false win detection")
		passed += 1
	else:
		print("❌ Test 11: False win detected")
		failed += 1
	
	# Test 12: Undo after game over
	state.reset()
	state.place_stone(7, 0)  # Black
	state.place_stone(0, 0)  # White
	state.place_stone(7, 1)  # Black
	state.place_stone(0, 1)  # White
	state.place_stone(7, 2)  # Black
	state.place_stone(0, 2)  # White
	state.place_stone(7, 3)  # Black
	state.place_stone(0, 3)  # White
	state.place_stone(7, 4)  # Black wins
	if state.game_over:
		state.undo_last_move()
		if not state.game_over:
			print("✅ Test 12: Undo clears game over")
			passed += 1
		else:
			print("❌ Test 12: Undo did not clear game over")
			failed += 1
	else:
		print("❌ Test 12: Setup failed")
		failed += 1
	
	print("📊 Results: %d passed, %d failed, %d total" % [passed, failed, passed + failed])
	if failed > 0:
		print("❌ SOME TESTS FAILED")
		get_tree().quit(1)
	else:
		print("✅ ALL TESTS PASSED")
		get_tree().quit(0)
