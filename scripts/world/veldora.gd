class_name Veldora
extends Node3D
## Veldora the Storm Dragon, sealed in the cave (design document, sections
## 9.3 and 18, act 1). He calls out to the sightless slime, teaches it Mana
## Perception, exchanges names with it as an equal, and can be carried away,
## seal and all, by agreement.
##
## What happens here is canon; his words (data/dialogues.json) and this
## placeholder body are original to this project. Every life meets him anew:
## the world does not remember the player, though the player may remember him.

const INTERACT_GROUP := "interactable"
const SOUND_GROUP := "sound_source"
const BARRIER_RADIUS := 8.0

## Points his voice seems to come from, leading through the cave to him.
var voice_path: Array[Vector3] = []

var _path_index := 0
var _busy := false
var _taken := false
var _body: Node3D


func _ready() -> void:
	add_to_group(INTERACT_GROUP)
	add_to_group(SOUND_GROUP)
	_body = Assets.instantiate("veldora")
	add_child(_body)
	_build_barrier()


# --- Interactable contract ---------------------------------------------------

func interact_range() -> float:
	return BARRIER_RADIUS + 6.0


func interact_label() -> String:
	return "Speak with Veldora" if Game.is_sighted() else "Answer the voice"


func can_interact() -> bool:
	return not _busy and not _taken


## Opens the conversation that fits how far this life has come with him.
func interact(_player: Player) -> void:
	var panel := get_tree().get_first_node_in_group(DialoguePanel.GROUP) as DialoguePanel
	if panel == null or not can_interact():
		return
	var flags := Game.life.flags
	var dialogue := "veldora_second"
	if not Game.is_sighted():
		dialogue = "veldora_waiting" if flags.has("mana_perception_taught") else "veldora_first"
	elif flags.has("veldora_named"):
		dialogue = "veldora_named"
	Game.count("talks")
	panel.start(dialogue, _on_effect)


# --- Sound source contract ---------------------------------------------------

func sound_label() -> String:
	return "a voice"


func sound_range() -> float:
	return 200.0


func is_audible() -> bool:
	return not _taken


## Where the voice seems to come from for a listener: the next point along
## the way to him, so that following the sound follows the passages.
func sound_position(listener: Vector3) -> Vector3:
	while _path_index < voice_path.size() and listener.distance_to(voice_path[_path_index]) < 5.0:
		_path_index += 1
	if _path_index < voice_path.size():
		return voice_path[_path_index]
	return global_position


# --- Story hooks -------------------------------------------------------------

func _on_effect(effect: String) -> void:
	match effect:
		"teach_mana_perception":
			Game.life.flags["mana_perception_taught"] = true
			Voice.advise("advisor_sense")
		"ask_names":
			_exchange_names()
		"offer_swallow":
			_offer_swallow()


func _exchange_names() -> void:
	var panel := get_tree().get_first_node_in_group(NamePanel.GROUP) as NamePanel
	if panel == null:
		return
	_busy = true
	var life := Game.life
	var names: Array = await panel.ask()
	_busy = false
	if Game.life != life or not life.alive:
		return
	life.given_name = str(names[0])
	life.family_name = str(names[1])
	life.flags["veldora_named"] = true
	Soul.remember("named_with_veldora", life.life_number)
	Game.count("names_received")
	Voice.say("named", {"name": life.full_name()})
	Game.add_ep(int(Database.tune("naming", "veldora_ep_gift", 200.0)), "naming")
	var dialogue := get_tree().get_first_node_in_group(DialoguePanel.GROUP) as DialoguePanel
	if dialogue != null:
		dialogue.start("veldora_named", _on_effect)


func _offer_swallow() -> void:
	_busy = true
	var life := Game.life
	var accepted: bool = await Voice.confirm("veldora_swallow_confirm")
	_busy = false
	if not accepted or Game.life != life or not life.alive or not life.has_skill("predator"):
		return
	_taken = true
	life.sealed.append("Veldora")
	life.flags["veldora_swallowed"] = true
	Soul.remember("carried_veldora", life.life_number)
	Game.count("swallowed_by_agreement")
	Voice.say("veldora_swallowed")
	remove_from_group(INTERACT_GROUP)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node3D
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE * 0.02, 1.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if player != null:
		tween.tween_property(self, "global_position", player.global_position, 1.4).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


# --- Body --------------------------------------------------------------------

## The Infinity Prison is a shell nothing passes. Its look, like the dragon's,
## comes from the asset manifest; its collision is his own.
func _build_barrier() -> void:
	var shell := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = BARRIER_RADIUS
	shape.shape = sphere
	shell.add_child(shape)
	shell.position.y = 1.0
	add_child(shell)
	shell.add_child(Assets.instantiate("veldora_seal", {"radius": BARRIER_RADIUS}))
