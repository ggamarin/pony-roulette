class_name Sfx
extends Node
## Простые звуки, синтезированные в коде (без аудиофайлов).

const RATE := 22050

var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_streams["boom"] = _synth("boom", 0.6)
	_streams["puff"] = _synth("puff", 0.35)
	_streams["click"] = _synth("click", 0.08)
	_streams["chime"] = _synth("chime", 0.45)
	_streams["load"] = _synth("load", 0.6)
	_streams["win"] = _synth("win", 0.8)


func play(kind: String) -> void:
	if muted or not _streams.has(kind):
		return
	var player := _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = _streams[kind]
	player.play()


func _synth(kind: String, dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ph := 0.0
	for i in n:
		var k := float(i) / n
		var v := 0.0
		match kind:
			"boom":
				ph += TAU * lerpf(150.0, 40.0, k) / RATE
				v = (sin(ph) * 0.7 + rng.randf_range(-1, 1) * 0.5) * pow(1.0 - k, 2.5)
			"puff":
				ph += TAU * lerpf(900.0, 1500.0, k) / RATE
				v = (rng.randf_range(-1, 1) * 0.25 + sin(ph) * 0.3) * pow(1.0 - k, 3.0)
			"click":
				ph += TAU * 260.0 / RATE
				v = (0.3 if sin(ph) > 0 else -0.3) * (1.0 - k)
			"chime", "win":
				var notes := [784.0, 988.0, 1175.0] if kind == "chime" else [523.0, 659.0, 784.0, 1047.0]
				var seg := k * notes.size()
				var idx := mini(int(seg), notes.size() - 1)
				ph += TAU * notes[idx] / RATE
				v = sin(ph) * 0.35 * (1.0 - fmod(seg, 1.0) * 0.7)
			"load":
				var seg := fmod(k * 5.0, 1.0)
				v = rng.randf_range(-1, 1) * 0.4 * pow(1.0 - seg, 8.0)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
