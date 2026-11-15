extends Node
## The Voice of the World (autoload "Voice"): the game's only announcer.
##
## Every system message goes through here. Line text lives in
## data/voice_lines.json; this script only decides when a line is spoken and
## on which channel. Lines are released one at a time at a steady pace so a
## burst of events still reads as a flat, even announcement.
##
##   Voice.say("skill_acquired", {"category": "Intrinsic skill", "skill": "Absorb"})
##   Voice.broadcast("...")                 # heard by everyone in range
##   Voice.advise("...")                    # the advisor skill: a different voice
##   if await Voice.confirm("..."): ...     # Yes/No prompt put to the player

## Emitted when a line is released. `line` has "channel", "text" and "key".
signal line_spoken(line: Dictionary)
signal confirm_opened(text: String)
signal confirm_closed(accepted: bool)
signal _confirm_answered(accepted: bool)

enum Channel {
	WORLD,      ## Addressed to the player alone.
	BROADCAST,  ## Addressed to everyone within range of an event.
	ADVISOR,    ## Not the Voice of the World: the player's advisor skill.
}

const LINE_INTERVAL := 0.45
const HISTORY_LIMIT := 200

## Lines already spoken, oldest first. Kept for a future message log screen.
var history: Array[Dictionary] = []

var _queue: Array[Dictionary] = []
var _cooldown := 0.0
var _confirm_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	# The Voice keeps its own pace even when the world slows down.
	delta /= maxf(Engine.time_scale, 0.01)
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	if _queue.is_empty():
		return
	var line: Dictionary = _queue.pop_front()
	history.append(line)
	if history.size() > HISTORY_LIMIT:
		history.pop_front()
	_cooldown = LINE_INTERVAL
	line_spoken.emit(line)


## Filled-in text of a line, without speaking it.
func text(key: String, params: Dictionary = {}) -> String:
	return Database.voice_line(key).format(params)


func say(key: String, params: Dictionary = {}, channel: Channel = Channel.WORLD) -> void:
	_queue.append({"channel": channel, "text": text(key, params), "key": key})


func broadcast(key: String, params: Dictionary = {}) -> void:
	say(key, params, Channel.BROADCAST)


func advise(key: String, params: Dictionary = {}) -> void:
	say(key, params, Channel.ADVISOR)


## Puts a Yes/No question to the player and waits for the answer.
## Questions asked while another is open wait their turn.
func confirm(key: String, params: Dictionary = {}) -> bool:
	while _confirm_active:
		await confirm_closed
	_confirm_active = true
	confirm_opened.emit(text(key, params))
	var accepted: bool = await _confirm_answered
	_confirm_active = false
	confirm_closed.emit(accepted)
	return accepted


## Called by the interface when the player answers the open question.
func answer(accepted: bool) -> void:
	if _confirm_active:
		_confirm_answered.emit(accepted)


func is_confirm_open() -> bool:
	return _confirm_active
