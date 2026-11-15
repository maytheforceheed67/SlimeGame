class_name Combat
extends RefCounted
## Shared combat rules. Anything in the "combatant" group can fight. A
## combatant is a Node3D with these methods:
##
##   get_faction() -> String        "player" or "wild"; different factions are hostile
##   get_vitals() -> Vitals
##   get_power() -> float           damage multiplier (EP for the player)
##   get_aim_origin() -> Vector3    centre of the body
##   get_body_radius() -> float
##   take_hit(hit: Dictionary) -> float   applies a hit, returns damage dealt
##
## A hit is {"amount", "damage_type", "attacker", "stagger", "status",
## "knockback"}; only amount and damage_type are required.

const GROUP := "combatant"
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const CREATURE_LAYER := 4
const CORPSE_LAYER := 8


static func are_hostile(a: Node, b: Node) -> bool:
	return a != b and a.get_faction() != b.get_faction()


## Living hostile combatants inside a cone in front of `origin`, nearest
## first. Bodies behind rock are skipped. `arc_degrees` is the full width.
static func targets_in_arc(user: Node3D, origin: Vector3, direction: Vector3,
		reach: float, arc_degrees: float) -> Array[Node3D]:
	var found: Array[Node3D] = []
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	var limit := cos(deg_to_rad(arc_degrees * 0.5))
	for node in user.get_tree().get_nodes_in_group(GROUP):
		var target := node as Node3D
		if target == null or not are_hostile(user, target) or not target.get_vitals().alive:
			continue
		var offset: Vector3 = target.get_aim_origin() - origin
		var distance := offset.length() - float(target.get_body_radius())
		if distance > reach or absf(offset.y) > reach + 1.5:
			continue
		var flat_offset := Vector3(offset.x, 0.0, offset.z)
		if flat_offset.length() > float(target.get_body_radius()) + 0.2 \
				and flat != Vector3.ZERO and flat.dot(flat_offset.normalized()) < limit:
			continue
		if not has_line_of_sight(user, origin, target.get_aim_origin()):
			continue
		found.append(target)
	found.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	return found


static func has_line_of_sight(user: Node3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_LAYER)
	return user.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Resolves one attack landing on one target. Returns the damage dealt.
static func strike(user: Node3D, target: Node3D, attack: Dictionary, direction: Vector3) -> float:
	if not is_instance_valid(target) or not target.get_vitals().alive:
		return 0.0
	var hit := {
		"amount": float(attack.get("damage", 0.0)) * float(user.get_power()),
		"damage_type": str(attack.get("damage_type", "impact")),
		"attacker": user,
		"stagger": float(attack.get("stagger", 0.0)),
		"knockback": Vector3(direction.x, 0.0, direction.z).normalized() * float(attack.get("knockback", 0.0)),
	}
	if attack.get("status") is Dictionary:
		hit["status"] = attack["status"]
	var dealt: float = target.take_hit(hit)
	var lifesteal := float(attack.get("lifesteal", 0.0))
	if user.has_method("get_lifesteal") and ["melee", "lunge"].has(str(attack.get("kind", ""))):
		lifesteal += float(user.get_lifesteal())
	if dealt > 0.0 and lifesteal > 0.0:
		user.get_vitals().heal(dealt * lifesteal)
	return dealt


## Applies a hit's status, if any, to a body's vitals.
static func apply_hit_status(vitals: Vitals, hit: Dictionary) -> void:
	var status: Variant = hit.get("status")
	if status is Dictionary:
		vitals.add_status(str(status.get("id", "")), float(status.get("duration", 1.0)),
				float(status.get("tick_damage", 0.0)))


## Colour used for an attack's effects.
static func attack_color(attack: Dictionary) -> Color:
	if attack.has("color"):
		return Color(str(attack["color"]))
	return Color(0.9, 0.9, 0.95)
