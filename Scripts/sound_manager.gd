# sound_manager.gd
# 程序化音效管理器 — 用 AudioStreamWAV 合成短音效
# 无需任何外部音频文件，全部代码生成
extends Node

var _place_bus: AudioStreamPlayer
var _undo_bus: AudioStreamPlayer
var _victory_bus: AudioStreamPlayer
var _click_bus: AudioStreamPlayer

const SAMPLE_RATE = 22050  # 低采样率就够了，音效短

func _ready():
	_place_bus = _make_player()
	_undo_bus = _make_player()
	_victory_bus = _make_player()
	_click_bus = _make_player()
	
	add_child(_place_bus)
	add_child(_undo_bus)
	add_child(_victory_bus)
	add_child(_click_bus)

func _make_player() -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.volume_db = -4.0
	return p

func play_place_stone():
	# 落子声: 清脆的中频冲击音 (模拟棋子落在棋盘)
	var data = _synthesize(0.1, func(t): 
		var freq = 600.0 + t * 3000.0  # 快速上升
		var amp = max(0, 1.0 - t * 12.0)  # 快速衰减
		return sin(freq * t * TAU) * amp * 0.5 + \
		       sin(freq * 1.5 * t * TAU) * amp * 0.25  # 谐波
	)
	_play_wav(_place_bus, data)

func play_undo():
	# 悔棋声: 向下滑音 (撤回感)
	var data = _synthesize(0.15, func(t):
		var freq = 800.0 - t * 2500.0
		var amp = max(0, 1.0 - t * 8.0)
		return sin(freq * t * TAU) * amp * 0.4
	)
	_play_wav(_undo_bus, data)

func play_victory():
	# 胜利声: C-E-G 上升和弦
	var data = _synthesize(0.5, func(t):
		var freq
		if t < 0.12: freq = 523.0   # C5
		elif t < 0.28: freq = 659.0  # E5
		else: freq = 784.0           # G5
		var amp = 1.0 - t * 1.8
		var vib = 1.0 + 0.03 * sin(t * 25.0)
		return sin(freq * vib * t * TAU) * amp * 0.5 + \
		       sin(freq * 0.5 * vib * t * TAU) * amp * 0.15
	)
	_play_wav(_victory_bus, data)

func play_click():
	# 按钮点击声: 极短的白噪声咔嗒
	var data = _synthesize(0.03, func(t):
		var amp = max(0, 1.0 - t * 40.0)
		# 使用正弦波代替噪声，更干净
		return sin(2500.0 * t * TAU) * amp * 0.25
	)
	_play_wav(_click_bus, data)

func _synthesize(duration: float, synth: Callable) -> PackedByteArray:
	var num_samples = int(SAMPLE_RATE * duration)
	var stereo_samples = num_samples * 2  # 16-bit stereo
	var data = PackedByteArray()
	data.resize(stereo_samples * 2)  # 2 bytes per sample
	
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var sample = synth.call(t)
		# Clamp
		sample = clamp(sample, -1.0, 1.0)
		# 16-bit signed
		var int_sample = int(sample * 32767)
		if int_sample < -32768: int_sample = -32768
		if int_sample > 32767: int_sample = 32767
		
		var offset = i * 4
		# Left channel (little-endian 16-bit)
		data.encode_s16(offset, int_sample)
		# Right channel (same for mono)
		data.encode_s16(offset + 2, int_sample)
	
	return data

func _play_wav(player: AudioStreamPlayer, pcm_data: PackedByteArray):
	# Use AudioStreamWAV for instant playback
	var wav = AudioStreamWAV.new()
	wav.data = pcm_data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = true
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	player.stream = wav
	player.play()
