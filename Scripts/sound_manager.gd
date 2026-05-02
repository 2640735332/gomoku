# sound_manager.gd
# 程序化音效管理器 — 全部代码生成，无外部文件
# 使用 AudioStreamPlayer + AudioStreamWAV 播放短音效
# BGM 使用实时合成 + 循环播放
extends Node

# ── 音频播放器 ──
var _place_bus: AudioStreamPlayer
var _undo_bus: AudioStreamPlayer
var _victory_bus: AudioStreamPlayer
var _click_bus: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer
var _bgm_stream: AudioStreamWAV

const SAMPLE_RATE = 22050

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
	print("🔊 SoundManager init...")
	_place_bus = _make_player(-4.0, "place")
	_undo_bus = _make_player(-4.0, "undo")
	_victory_bus = _make_player(-2.0, "victory")
	_click_bus = _make_player(-6.0, "click")
	_bgm_player = _make_player(-4.0, "bgm")
	print("🔊 SoundManager ready")

func _make_player(vol: float, name_hint: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.volume_db = vol
	p.name = name_hint
	add_child(p)
	return p

# ══════════════════════════════════════════
# 短音效（AudioStreamWAV 紧凑合成）
# ══════════════════════════════════════════

func make_wav_bytes(duration: float, synth: Callable) -> PackedByteArray:
	"""合成 16-bit mono PCM 数据（使用 mono 减少兼容问题）"""
	var n = int(SAMPLE_RATE * duration)
	var buf = PackedByteArray()
	buf.resize(n * 2)  # 16-bit mono
	var t_step = 1.0 / SAMPLE_RATE
	var t = 0.0
	for i in range(n):
		var s = clamp(synth.call(t), -1.0, 1.0)
		var v = clampi(int(s * 32767), -32768, 32767)
		buf.encode_s16(i * 2, v)
		t += t_step
	return buf

func _play_pcm(player: AudioStreamPlayer, pcm: PackedByteArray):
	var wav = AudioStreamWAV.new()
	wav.data = pcm
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	player.stream = wav
	player.play()

func play_place_stone():
	var pcm = make_wav_bytes(0.1, func(t):
		var f = 600.0 + t * 3000.0
		var a = max(0, 1.0 - t * 12.0)
		return sin(f * t * TAU) * a * 0.5 + sin(f * 1.5 * t * TAU) * a * 0.25
	)
	_play_pcm(_place_bus, pcm)

func play_undo():
	var pcm = make_wav_bytes(0.12, func(t):
		var f = 800.0 - t * 2500.0
		var a = max(0, 1.0 - t * 10.0)
		return sin(f * t * TAU) * a * 0.4
	)
	_play_pcm(_undo_bus, pcm)

func play_click():
	var pcm = make_wav_bytes(0.03, func(t):
		return sin(2500.0 * t * TAU) * max(0, 1.0 - t * 40.0) * 0.25
	)
	_play_pcm(_click_bus, pcm)

func play_victory_black():
	var pcm = make_wav_bytes(0.8, func(t):
		var a = max(0, 1.0 - t * 1.1)
		var c = sin(130.81 * t * TAU) * 0.4
		var e = sin(164.81 * t * TAU) * 0.25
		var g = sin(196.0 * t * TAU) * 0.2
		var d = sin(45.0 * t * TAU) * exp(-t * 6.0) * 0.3
		return (c + e + g + d) * a * 0.5
	)
	_play_pcm(_victory_bus, pcm)

func play_victory_white():
	var pcm = make_wav_bytes(0.8, func(t):
		var a = max(0, 1.0 - t * 1.1)
		var v = 1.0 + 0.02 * sin(t * 30.0)
		var f
		if t < 0.15: f = 523.25
		elif t < 0.3: f = 659.25
		elif t < 0.5: f = 783.99
		else: f = 1046.5
		return sin(f * v * t * TAU) * a * 0.5 + sin(f * 0.5 * v * t * TAU) * a * 0.2
	)
	_play_pcm(_victory_bus, pcm)

# ══════════════════════════════════════════
# BGM 系统 — 预合成 + 手动循环
# ══════════════════════════════════════════

var _bgm_idle_pcm: PackedByteArray = PackedByteArray()
var _bgm_black_pcm: PackedByteArray = PackedByteArray()
var _bgm_white_pcm: PackedByteArray = PackedByteArray()
var _current_bgm: String = ""

func _init():
	# 在 _ready() 前预合成 BGM，避免启动卡顿
	_bgm_idle_pcm = _synth_bgm(_gen_pentatonic_idle(0.6))
	_bgm_black_pcm = _synth_bgm(_gen_heroic_bgm(0.6))
	_bgm_white_pcm = _synth_bgm(_gen_triumphant_bgm(0.6))

func _synth_bgm(gen: Callable) -> PackedByteArray:
	"""合成 20 秒 BGM 循环"""
	var dur = 20.0
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedByteArray()
	buf.resize(n * 2)
	var t = 0.0
	var step = 1.0 / SAMPLE_RATE
	for i in range(n):
		var s = clamp(gen.call(t), -1.0, 1.0)
		var v = clampi(int(s * 32767), -32768, 32767)
		buf.encode_s16(i * 2, v)
		t += step
	return buf

func _play_bgm_internal(pcm: PackedByteArray):
	if _bgm_player.stream:
		_bgm_player.stop()
	var wav = AudioStreamWAV.new()
	wav.data = pcm
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_bgm_player.stream = wav
	_bgm_player.play()

func start_bgm():
	if not _current_bgm:
		_current_bgm = "idle"
		_play_bgm_internal(_bgm_idle_pcm)
		# 用 Timer 手动循环
		_bgm_player.finished.connect(_on_bgm_loop)

func _on_bgm_loop():
	# BGM 循环回放
	if _bgm_player.stream:
		_bgm_player.play()

func stop_bgm():
	_current_bgm = ""
	_bgm_player.stop()
	_bgm_player.stream = null

func transition_bgm(new_id: String):
	if _current_bgm == new_id:
		return
	_current_bgm = new_id
	match new_id:
		"victory_black":
			_play_bgm_internal(_bgm_black_pcm)
		"victory_white":
			_play_bgm_internal(_bgm_white_pcm)
		_:
			_play_bgm_internal(_bgm_idle_pcm)

func is_bgm_playing() -> bool:
	return _bgm_player.playing and _bgm_player.stream != null

# ══════════════════════════════════════════
# BGM 波形生成器
# ══════════════════════════════════════════

func _gen_pentatonic_idle(vol: float) -> Callable:
	var notes = [
		PENTATONIC["C4"], PENTATONIC["E4"], PENTATONIC["G4"], PENTATONIC["A4"],
		PENTATONIC["G4"], PENTATONIC["E4"], PENTATONIC["D4"], PENTATONIC["C4"],
		PENTATONIC["E4"], PENTATONIC["A4"], PENTATONIC["G4"], PENTATONIC["E4"],
	]
	var ndur = 1.8
	var cycle = ndur * len(notes)
	return func(t: float):
		var lt = fmod(t, cycle)
		var idx = int(lt / ndur) % len(notes)
		var nt = fmod(lt, ndur) / ndur
		var env = min(nt * 4.0, 1.0) * max(0, 1.0 - nt * 0.4)
		var vib = 1.0 + 0.015 * sin(t * 8.0)
		var f = notes[idx] * vib
		var mel = sin(f * t * TAU) * env * 0.18 + sin(f * 0.5 * t * TAU) * env * 0.08
		var drone = sin(130.81 * t * TAU) * 0.05 + sin(196.0 * t * TAU) * 0.03
		var pad = sin(261.63 * t * TAU) * 0.012 + sin(329.63 * t * TAU) * 0.01 + sin(392.0 * t * TAU) * 0.008
		return (mel + drone + pad) * vol

func _gen_heroic_bgm(vol: float) -> Callable:
	var notes = [
		PENTATONIC["C2"], PENTATONIC["G2"], PENTATONIC["C3"], PENTATONIC["E3"],
		PENTATONIC["G3"], PENTATONIC["C4"], PENTATONIC["G3"], PENTATONIC["E3"],
		PENTATONIC["C3"], PENTATONIC["G2"], PENTATONIC["C3"], PENTATONIC["G2"],
		PENTATONIC["C2"], PENTATONIC["G2"], PENTATONIC["E3"], PENTATONIC["C3"],
	]
	var ndur = 1.2
	var cycle = ndur * len(notes)
	return func(t: float):
		var lt = fmod(t, cycle)
		var idx = int(lt / ndur) % len(notes)
		var nt = fmod(lt, ndur) / ndur
		var env = min(nt * 6.0, 1.0) * max(0, 1.0 - nt * 0.6)
		var f = notes[idx]
		var bass = sin(f * t * TAU) * env * 0.12 + sin(f * 2.0 * t * TAU) * env * 0.03
		var chord_t = fmod(t, 3.0)
		var cf = PENTATONIC["C4"] if chord_t < 1.5 else PENTATONIC["G4"]
		var ce = max(0, 1.0 - chord_t * 0.2)
		var chord = sin(cf * t * TAU) * ce * 0.06 + sin(cf * 1.5 * t * TAU) * ce * 0.04
		var beat_t = fmod(t, 3.0)
		var beat = sin(60.0 * t * TAU) * (max(0, 1.0 - beat_t * 12.0) if beat_t < 0.15 else 0.0) * 0.15
		return (bass + chord + beat) * vol

func _gen_triumphant_bgm(vol: float) -> Callable:
	var notes = [
		PENTATONIC["C5"], PENTATONIC["E5"], PENTATONIC["G5"], PENTATONIC["A5"],
		PENTATONIC["C6"], PENTATONIC["A5"], PENTATONIC["G5"], PENTATONIC["E5"],
	]
	var ndur = 0.2
	var cycle = ndur * len(notes)
	return func(t: float):
		var lt = fmod(t, cycle)
		var idx = int(lt / ndur) % len(notes)
		var nt = fmod(lt, ndur) / ndur
		var env = min(nt * 8.0, 1.0) * max(0, 1.0 - nt * 3.0)
		var f = notes[idx]
		var mel = sin(f * t * TAU) * env * 0.15 + sin(f * 2.0 * t * TAU) * env * 0.04 + sin(f * 3.0 * t * TAU) * env * 0.015
		var bass = sin(196.0 * t * TAU) * 0.03
		var vib = 1.0 + 0.02 * sin(t * 12.0)
		var shimmer = sin(523.25 * vib * t * TAU) * 0.025 + sin(659.25 * vib * t * TAU) * 0.015
		var beat_t = fmod(t, 1.5)
		var beat = sin(800.0 * t * TAU) * (max(0, 1.0 - beat_t * 18.0) if beat_t < 0.08 else 0.0) * 0.12
		return (mel + bass + shimmer + beat) * vol
