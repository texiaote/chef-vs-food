extends Node

## Named sound slots. v0.1 ships them empty.
## Drop assets/audio/<slot>.ogg (or .wav) and it is picked up on the next launch,
## or assign AudioManager.streams[slot] at runtime.

const SLOT_NAMES: PackedStringArray = [
	"ui_confirm",
	"ui_move",
	"shoot",
	"swing",
	"hit",
	"enemy_death",
	"player_hurt",
	"xp_pickup",
	"level_up",
	"evolution",
	"boss_spawn",
	"boss_death",
	"win",
	"lose",
]

var streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for slot_name in SLOT_NAMES:
		streams[slot_name] = _find_stream(String(slot_name))
	for _i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func play(slot: String) -> void:
	var stream: AudioStream = streams.get(slot)
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	_players[0].stream = stream
	_players[0].play()


func _find_stream(slot_name: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/audio/%s.%s" % [slot_name, ext]
		if ResourceLoader.exists(path):
			var loaded = load(path)
			if loaded is AudioStream:
				return loaded
	return null
