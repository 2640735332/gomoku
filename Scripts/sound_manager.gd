# sound_manager.gd
# 程序化音效管理器 — 用 AudioStreamWAV 合成音效 + BGM
# 无需任何外部音频文件，全部代码生成
extends Node

# ── 音效播放器（短音效） ──
var _place_bus: AudioStreamPlayer
var _undo_bus: AudioStreamPlayer
var _victory_bus: AudioStreamPlayer  # 复用为当前胜利音效
var _click_bus: AudioStreamPlayer

# ── BGM 播放器 ──
var _bgm_player: AudioStreamPlayer
var _current_bgm_data: PackedByteArray = PackedByteArray()
var _current_bgm_id: String = ""
var _bgm_volume_db: float = -10.0

const SAMPLE_RATE = 22050  # 低采样率足够
const BGM_SAMPLE_RATE = 22050  # BGM 同样

# 中国五声音阶频率 (C4 宫调式 = C D E G A)
const PENTATONIC = {
	"C4": 261.63, "D4": 293.66, "E4": 329.63,
	"G4": 392.0, "A4": 440.0,
	"C5": 523.25, "D5": 587.33, "E5": 659.25,
	"G5": 783.99, "A5": 880.0, "C6": 1046.5,
	"C3": 130.81, "D3": 146.83, "E3": 164.81,
	"G3": 196.0, "A3": 220.0,
	"C2": 65.41, "G2": 98.0,
}

func _ready():
	# 短音效播放器
	_place_bus = _make_player(-4.0)
	_undo_bus = _make_player(-4.0)
	_victory_bus = _make_player(-2.0)
	_click_bus = _make_player(-6.0)
	
	add_child(_place_bus)
	add_child(_undo_bus)
	add_child(_victory_bus)
	add_child(_click_bus)
	
	# BGM 播放器
	_bgm_player = _make_player(-8.0)
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

func _make_player(volume_db: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.volume_db = volume_db
	return p

# ══════════════════════════════════════════
# BGM 系统
# ══════════════════════════════════════════

func _on_bgm_finished():
	"""BGM 循环播放"""
	if _bgm_player.stream:
		_bgm_player.play()

func start_bgm():
	"""开始播放背景音乐"""
	if not _current_bgm_id:
		_current_bgm_id = "idle"
		_current_bgm_data = _synthesize_bgm(_generate_pentatonic_idle(60.0))
		var wav = _make_wav(_current_bgm_data, BGM_SAMPLE_RATE, true)
		_bgm_player.stream = wav
	_bgm_player.play()

func stop_bgm():
	"""停止 BGM"""
	_bgm_player.stop()
	_bgm_player.stream = null

func transition_bgm(new_bgm_id: String):
	"""切换到新的 BGM 类型"""
	if _current_bgm_id == new_bgm_id:
		return
	
	_current_bgm_id = new_bgm_id
	
	if new_bgm_id == "victory_black":
		_current_bgm_data = _synthesize_bgm(_generate_heroic_bgm(20.0, 0.5))
	elif new_bgm_id == "victory_white":
		_current_bgm_data = _synthesize_bgm(_generate_triumphant_bgm(20.0, 0.5))
	else:
		_current_bgm_data = _synthesize_bgm(_generate_pentatonic_idle(60.0))
	
	_bgm_player.stream = _make_wav(_current_bgm_data, BGM_SAMPLE_RATE, true)
	_bgm_player.play()

func _make_wav(pcm_data: PackedByteArray, sample_rate: int, loop: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.data = pcm_data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = true
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	return wav

func _synthesize_bgm(generator: Callable) -> PackedByteArray:
	"""合成 BGM 循环（16-bit stereo PCM）"""
	var duration = 60.0  # 60秒循环
	var num_samples = int(BGM_SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 4)  # 2 samples * 2 bytes
	
	var t_step = 1.0 / BGM_SAMPLE_RATE
	var t = 0.0
	for i in range(num_samples):
		var sample = generator.call(t)
		sample = clamp(sample, -1.0, 1.0)
		var int_sample = int(sample * 32767)
		int_sample = clampi(int_sample, -32768, 32767)
		
		var offset = i * 4
		data.encode_s16(offset, int_sample)     # L
		data.encode_s16(offset + 2, int_sample)  # R
	
	return data

func _generate_pentatonic_idle(duration: float) -> Callable:
	"""生成平和的中国风BGM（五声音阶即兴循环）"""
	# 音符序列：缓慢的琶音上行下行
	var notes = [
		{"freq": PENTATONIC["C4"], "dur": 2.0},
		{"freq": PENTATONIC["E4"], "dur": 2.0},
		{"freq": PENTATONIC["G4"], "dur": 2.0},
		{"freq": PENTATONIC["A4"], "dur": 2.0},
		{"freq": PENTATONIC["G4"], "dur": 1.5},
		{"freq": PENTATONIC["E4"], "dur": 1.5},
		{"freq": PENTATONIC["D4"], "dur": 1.5},
		{"freq": PENTATONIC["C4"], "dur": 1.5},
		{"freq": PENTATONIC["E4"], "dur": 2.0},
		{"freq": PENTATONIC["A4"], "dur": 1.5},
		{"freq": PENTATONIC["G4"], "dur": 1.0},
		{"freq": PENTATONIC["E4"], "dur": 1.0},
		{"freq": PENTATONIC["D4"], "dur": 0.75},
		{"freq": PENTATONIC["C5"], "dur": 0.75},
		{"freq": PENTATONIC["A4"], "dur": 0.75},
		{"freq": PENTATONIC["G4"], "dur": 0.75},
		{"freq": PENTATONIC["E4"], "dur": 1.5},
		{"freq": PENTATONIC["C4"], "dur": 3.0},
		{"freq": PENTATONIC["G3"], "dur": 2.0},
		{"freq": PENTATONIC["A3"], "dur": 2.0},
		{"freq": PENTATONIC["C4"], "dur": 2.0},
		{"freq": PENTATONIC["E4"], "dur": 2.0},
		{"freq": PENTATONIC["D4"], "dur": 1.5},
		{"freq": PENTATONIC["C4"], "dur": 1.5},
		{"freq": PENTATONIC["A3"], "dur": 1.0},
		{"freq": PENTATONIC["G3"], "dur": 1.0},
		{"freq": PENTATONIC["E3"], "dur": 1.0},
		{"freq": PENTATONIC["G3"], "dur": 1.0},
		{"freq": PENTATONIC["C4"], "dur": 4.0},
		{"freq": PENTATONIC["E4"], "dur": 2.0},
		{"freq": PENTATONIC["G4"], "dur": 2.0},
	]
	
	var cycle_dur = 0.0
	for n in notes:
		cycle_dur += n.dur
	
	# 低音持续音 (C3 drone)
	var drone_freq = PENTATONIC["C3"]
	var drone_freq2 = PENTATONIC["G3"]
	
	return func(t: float):
		var loop_t = fmod(t, cycle_dur)
		var accum = 0.0
		var freq = PENTATONIC["C4"]
		var note_amp = 0.0
		var vibrato = 0.0
		
		for n in notes:
			var next_accum = accum + n.dur
			if loop_t >= accum and loop_t < next_accum:
				var nt = (loop_t - accum) / n.dur
				# 包络：起音 + 衰减
				var env = min(nt * 4.0, 1.0)  # 快速起音
				env *= max(0, 1.0 - nt * 0.3)  # 缓慢衰减
				freq = n.freq
				note_amp = env
				# 颤音（中国风韵味）
				vibrato = 1.0 + 0.015 * sin(t * 8.0 + freq * 0.1)
				break
			accum = next_accum
		
		# 主旋律
		var melody = sin(freq * vibrato * t * TAU) * note_amp * 0.2
		# 次谐波柔和
		melody += sin(freq * 0.5 * t * TAU) * note_amp * 0.1
		
		# 低音持续音（C3 drone + G3 五度）
		var drone = 0.0
		drone += sin(drone_freq * t * TAU) * 0.06
		drone += sin(drone_freq2 * t * TAU) * 0.04
		
		# 填充音（柔和的和声背景）
		var pad = 0.0
		pad += sin(PENTATONIC["C4"] * t * TAU) * 0.015
		pad += sin(PENTATONIC["E4"] * t * TAU) * 0.012
		pad += sin(PENTATONIC["G4"] * t * TAU) * 0.01
		
		return melody + drone + pad

func _generate_heroic_bgm(duration: float, volume_scale: float) -> Callable:
	"""黑方胜利 BGM — 深沉、蓄力、史诗感（低音走向）"""
	# 低音行进：C2 - G2 - C3 - E3 - G3 - C4
	var bass_notes = [
		PENTATONIC["C2"], PENTATONIC["G2"],
		PENTATONIC["C3"], PENTATONIC["E3"],
		PENTATONIC["G3"], PENTATONIC["C4"],
		PENTATONIC["G3"], PENTATONIC["E3"],
		PENTATONIC["C3"], PENTATONIC["G2"],
		PENTATONIC["C3"], PENTATONIC["G2"],
		PENTATONIC["C2"], PENTATONIC["G2"],
		PENTATONIC["E3"], PENTATONIC["C3"],
	]
	var bass_dur = 1.5
	var cycle_dur = bass_dur * len(bass_notes)
	
	return func(t: float):
		var loop_t = fmod(t, cycle_dur)
		var bass_idx = int(loop_t / bass_dur)
		var bass_nt = fmod(loop_t, bass_dur) / bass_dur
		var bass_freq = bass_notes[bass_idx]
		var bass_env = min(bass_nt * 8.0, 1.0) * max(0, 1.0 - bass_nt * 0.5)
		
		# 低音 — 深沉有力
		var output = 0.0
		output += sin(bass_freq * t * TAU) * bass_env * 0.15
		output += sin(bass_freq * 2.0 * t * TAU) * bass_env * 0.04
		
		# 中音和弦 — 进行感
		var chord_t = fmod(t, 4.0)
		var chord_freq = PENTATONIC["C4"]
		var chord_env = max(0, 1.0 - chord_t * 0.15)
		if chord_t < 2.0:
			chord_freq = PENTATONIC["C4"]
		else:
			chord_freq = PENTATONIC["G4"]
		output += sin(chord_freq * t * TAU) * chord_env * 0.08
		output += sin(chord_freq * 1.5 * t * TAU) * chord_env * 0.05
		
		# 鼓点冲击（每4拍一个）
		var beat_t = fmod(t, 4.0)
		var beat_env = max(0, 1.0 - beat_t * 10.0) if beat_t < 0.2 else 0.0
		output += sin(60.0 * t * TAU) * beat_env * 0.2
		
		return output * volume_scale

func _generate_triumphant_bgm(duration: float, volume_scale: float) -> Callable:
	"""白方胜利 BGM — 明亮、欢快、上升（高音琶音）"""
	# 琶音上行循环：C5 E5 G5 A5 C6 A5 G5 E5 ...
	var arp_notes = [
		PENTATONIC["C5"], PENTATONIC["E5"],
		PENTATONIC["G5"], PENTATONIC["A5"],
		PENTATONIC["C6"], PENTATONIC["A5"],
		PENTATONIC["G5"], PENTATONIC["E5"],
	]
	var arp_dur = 0.25  # 快速琶音
	var cycle_dur = arp_dur * len(arp_notes)
	
	return func(t: float):
		var loop_t = fmod(t, cycle_dur)
		var arp_idx = int(loop_t / arp_dur)
		var arp_nt = fmod(loop_t, arp_dur) / arp_dur
		var arp_freq = arp_notes[arp_idx]
		var arp_env = min(arp_nt * 10.0, 1.0) * max(0, 1.0 - arp_nt * 2.0)
		
		# 主音 — 明亮上升
		var output = 0.0
		output += sin(arp_freq * t * TAU) * arp_env * 0.18
		output += sin(arp_freq * 2.0 * t * TAU) * arp_env * 0.05
		
		# 高音泛音 — 闪烁感
		output += sin(arp_freq * 3.0 * t * TAU) * arp_env * 0.02
		
		# 低音支持（G3 持续）
		output += sin(PENTATONIC["G3"] * t * TAU) * 0.04
		
		# 颤音效果 — 整个音色更活泼
		var vib = 1.0 + 0.02 * sin(t * 12.0)
		output += sin(PENTATONIC["C5"] * vib * t * TAU) * 0.03
		output += sin(PENTATONIC["E5"] * vib * t * TAU) * 0.02
		
		# 欢快的短冲击（每两拍）
		var beat_t = fmod(t, 2.0)
		var beat_env = max(0, 1.0 - beat_t * 15.0) if beat_t < 0.1 else 0.0
		output += sin(800.0 * t * TAU) * beat_env * 0.15
		
		return output * volume_scale

# ══════════════════════════════════════════
# 短音效
# ══════════════════════════════════════════

func play_place_stone():
	var data = _synthesize(0.1, func(t): 
		var freq = 600.0 + t * 3000.0
		var amp = max(0, 1.0 - t * 12.0)
		return sin(freq * t * TAU) * amp * 0.5 + \
		       sin(freq * 1.5 * t * TAU) * amp * 0.25
	)
	_play_wav(_place_bus, data, SAMPLE_RATE)

func play_undo():
	var data = _synthesize(0.15, func(t):
		var freq = 800.0 - t * 2500.0
		var amp = max(0, 1.0 - t * 8.0)
		return sin(freq * t * TAU) * amp * 0.4
	)
	_play_wav(_undo_bus, data, SAMPLE_RATE)

func play_victory():
	"""旧兼容接口 — 默认播放黑方胜利（由 main.gd 调用专门的版本）"""
	play_victory_black()

func play_victory_black():
	"""黑方胜利音效：深沉的低音和弦 C3 E3 G3 → 加重低音后释放"""
	var data = _synthesize(0.8, func(t):
		var amp = max(0, 1.0 - t * 1.1)
		# C3 + E3 + G3 低音和弦
		var c3 = sin(PENTATONIC["C3"] * t * TAU) * 0.4
		var e3 = sin(PENTATONIC["E3"] * t * TAU) * 0.25
		var g3 = sin(PENTATONIC["G3"] * t * TAU) * 0.2
		# 低频冲击（模拟大鼓）
		var drum = sin(45.0 * t * TAU) * exp(-t * 6.0) * 0.3
		return (c3 + e3 + g3 + drum) * amp * 0.5
	)
	_play_wav(_victory_bus, data, SAMPLE_RATE)

func play_victory_white():
	"""白方胜利音效：明亮的上升琶音 C5 E5 G5 C6 + 泛音"""
	var data = _synthesize(0.8, func(t):
		var amp = max(0, 1.0 - t * 1.1)
		var vib = 1.0 + 0.02 * sin(t * 30.0)
		# C5 E5 G5 C6 快速琶音
		var freq
		if t < 0.15: freq = PENTATONIC["C5"]
		elif t < 0.3: freq = PENTATONIC["E5"]
		elif t < 0.5: freq = PENTATONIC["G5"]
		else: freq = PENTATONIC["C6"]
		return sin(freq * vib * t * TAU) * amp * 0.5 + \
		       sin(freq * 0.5 * vib * t * TAU) * amp * 0.2 + \
		       sin(freq * 2.0 * vib * t * TAU) * amp * 0.1
	)
	_play_wav(_victory_bus, data, SAMPLE_RATE)

func play_click():
	var data = _synthesize(0.03, func(t):
		var amp = max(0, 1.0 - t * 40.0)
		return sin(2500.0 * t * TAU) * amp * 0.25
	)
	_play_wav(_click_bus, data, SAMPLE_RATE)

# ══════════════════════════════════════════
# 内部工具函数
# ══════════════════════════════════════════

func _synthesize(duration: float, synth: Callable) -> PackedByteArray:
	var num_samples = int(SAMPLE_RATE * duration)
	var stereo_samples = num_samples * 2
	var data = PackedByteArray()
	data.resize(stereo_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var sample = synth.call(t)
		sample = clamp(sample, -1.0, 1.0)
		var int_sample = int(sample * 32767)
		int_sample = clampi(int_sample, -32768, 32767)
		
		var offset = i * 4
		data.encode_s16(offset, int_sample)
		data.encode_s16(offset + 2, int_sample)
	
	return data

func _play_wav(player: AudioStreamPlayer, pcm_data: PackedByteArray, sample_rate: int):
	var wav = AudioStreamWAV.new()
	wav.data = pcm_data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = true
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	player.stream = wav
	player.play()
