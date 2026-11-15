extends TestCase
## Visual pipeline: the visual config, the look it gives the level, the asset
## manager and its stand-ins, the F4 panel (overhaul Pass 0), and the toon
## material, ink lines, key light and blob shadows (Pass 1).


func _run() -> void:
	print("Visual pipeline")

	# The config: typed lookups by dotted path.
	check(Visual.color("palette.cave.fog").is_equal_approx(Color.html("#2A2466")), "colours are read by dotted path")
	check(is_equal_approx(Visual.number("post.bloom_threshold"), 1.0), "numbers are read by dotted path")
	check(Visual.flag("accessibility.reduce_flashes") == false and Visual.text("renderer.tonemap") == "linear",
			"flags and text are read by dotted path")
	check(is_equal_approx(Visual.number("accessibility.screen_shake"), 1.0) and is_equal_approx(Visual.number("accessibility.hit_stop_scale"), 1.0),
			"accessibility switches exist from the start")
	check(Visual.entries().size() > 100, "every setting is listed for the editor (%d)" % Visual.entries().size())

	# Live edits, overrides and saving.
	var heard: Array[String] = []
	Visual.changed.connect(func(path: String) -> void: heard.append(path))
	check(Visual.set_value("fog.density", 0.05) and heard == ["fog.density"], "changing a value notifies listeners")
	check(is_equal_approx(Visual.number("fog.density"), 0.05) and Visual.is_overridden("fog.density"), "the change is kept as an override")
	check(not Visual.set_value("fog.density", "thick") and not Visual.set_value("fog.nonsense", 1.0), "a wrong kind or an unknown path is refused")
	Visual.save_overrides()
	Visual.reload()
	check(is_equal_approx(Visual.number("fog.density"), 0.05), "saved overrides are laid over the shipped file")
	Visual.reset()
	Visual.save_overrides()
	check(is_equal_approx(Visual.number("fog.density"), 0.018) and not Visual.is_overridden("fog.density"), "reset returns to the shipped values")

	# The level takes its look from the config.
	await start_main()
	var environment: Environment = main.level._environment
	check(environment.background_color.is_equal_approx(Visual.color("palette.cave.fog")) \
			and environment.fog_light_color.is_equal_approx(Visual.color("palette.cave.fog")),
			"fog and background share the palette's fog colour")
	check(environment.tonemap_mode == Environment.TONE_MAPPER_LINEAR, "tone mapping is linear, not ACES")
	check(environment.glow_enabled and is_equal_approx(environment.glow_hdr_threshold, 1.0), "bloom starts at a threshold of 1: only emissive glows")
	check(get_viewport().msaa_3d == Viewport.MSAA_2X, "anti-aliasing follows the config")
	Visual.set_value("fog.density", 0.04)
	Visual.set_value("renderer.antialiasing", "msaa4x")
	check(is_equal_approx(environment.fog_density, 0.04), "a live edit reaches the level at once")
	check(get_viewport().msaa_3d == Viewport.MSAA_4X, "including the anti-aliasing mode")
	Visual.set_value("renderer.antialiasing", "fxaa")
	check(WorldLook.on_compatibility_renderer() and get_viewport().msaa_3d == Viewport.MSAA_2X,
			"on the Compatibility renderer, which has no FXAA, that choice means 2x multisampling")
	Visual.reset()
	check(WorldLook.tone_mapper("nonsense") == 0, "an unknown tone mapper falls back to linear")
	var vignette: ColorRect = main.get_node("HUD/Vignette")
	check(vignette.visible and is_equal_approx(vignette.material.get_shader_parameter("darkness"), 0.45), "the vignette takes its strength from the config")

	# A sightless body still gets its darkness.
	check(environment.fog_mode == Environment.FOG_MODE_EXPONENTIAL, "a sighted body sees coloured fog")
	Game.life.skills.erase("mana_perception")
	await frames(3)
	check(environment.fog_mode == Environment.FOG_MODE_DEPTH and environment.fog_light_color == Color.BLACK,
			"a sightless body still sees only what it can touch")
	Visual.set_value("fog.density", 0.03)
	check(environment.fog_mode == Environment.FOG_MODE_DEPTH and environment.fog_light_color == Color.BLACK,
			"editing a setting while sightless does not let the light in, even for a frame")
	Visual.reset()
	Game.grant_skill("mana_perception", true)
	await frames(3)
	check(environment.fog_light_color.is_equal_approx(Visual.color("palette.cave.fog")), "and the coloured fog returns with sight")

	# The asset manager: every model comes through the manifest.
	for id: String in Assets.manifest:
		var builder := str(Assets.entry(id).get("placeholder", {}).get("builder", ""))
		check(StandIns.BUILDERS.has(builder), "manifest entry '%s' names a known stand-in" % id)
		var model := Assets.instantiate(id)
		check(model != null and (model is VisualInstance3D or model.get_child_count() > 0), "'%s' builds a model" % id)
		model.free()
	check(Assets.warnings.is_empty(), "no asset in the manifest is missing")
	check(player.get_node_or_null("Visual/Slime/Body") != null, "the slime's body comes from the manifest")

	Assets.manifest["test_missing_file"] = {"id": "test_missing_file", "file": "assets/models/props/not_there.glb",
			"target_height": 1.0, "placeholder": {"builder": "mote_orb", "seed": 0}}
	var first := Assets.instantiate("test_missing_file")
	var second := Assets.instantiate("test_missing_file")
	check(first is MeshInstance3D and second is MeshInstance3D, "a missing file yields the stand-in")
	check(Assets.warnings.size() == 1 and Assets.warnings[0].contains("not_there.glb"), "and exactly one warning")
	var unknown := Assets.instantiate("no_such_asset")
	check(unknown != null and unknown.name == "MissingAsset" and Assets.warnings.size() == 2, "an id that is not in the manifest shows a marker and warns once")
	first.free()
	second.free()
	unknown.free()
	Assets.reload()

	# A real file named by the manifest is loaded and scaled to its height.
	Assets.manifest["test_rock"] = {"id": "test_rock", "file": "tests/fixtures/test_rock.glb",
			"target_height": 0.5, "placeholder": {"builder": "mote_orb", "seed": 0}}
	var rock := Assets.instantiate("test_rock")
	var fitted := rock.get_child(0) as Node3D
	check(fitted.name == "TestRock" and is_equal_approx(fitted.scale.y, 0.25), "a model file in the manifest is loaded and scaled to its target height")
	check(Assets.warnings.is_empty(), "with no warning")
	rock.scale = Vector3.ONE * 0.3
	rock.position.y = 2.0
	check(is_equal_approx(fitted.scale.y, 0.25) and is_zero_approx(fitted.position.y), "the fit survives the caller moving and scaling the model")
	rock.free()
	Assets.reload()

	# Scaling a loaded model to its manifest height.
	var crate := Node3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 2.0, 1.0)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position.y = 1.5
	crate.add_child(part)
	Assets.fit_height(crate, 1.0)
	check(is_equal_approx(crate.scale.y, 0.5) and is_equal_approx(crate.position.y, -0.25), "fit_height scales a model to its height and rests it on the floor")
	crate.free()

	await _test_toon()

	# The F4 panel.
	var panel: Control = main.get_node("HUD/VisualPanel")
	await tap("debug_visual_panel")
	check(panel.is_open() and panel._rows.get_child_count() == Visual.entries().size(), "F4 opens an editor with a row per setting")
	check(not Game.can_control(), "the body takes no input while the editor is open")
	panel._changed("post.bloom_intensity", 1.2)
	check(is_equal_approx(environment.glow_intensity, 1.2), "editing a row changes the look at once")
	panel._reset_all()
	check(is_equal_approx(environment.glow_intensity, 0.8), "Reset all restores the shipped look")
	await tap("debug_visual_panel")
	check(not panel.is_open() and Game.can_control(), "F4 closes it again")
	var sheet: Control = main.get_node("HUD/StatusSheet")
	sheet.open()
	await tap("debug_visual_panel")
	check(panel.is_open(), "the editor also opens while the status sheet has paused the world")
	sheet.close()
	check(Game.ui_locks == 1 and Game._cursor_locks == 1, "closing the sheet leaves the editor's hold on input and cursor")
	await tap("debug_visual_panel")
	check(Game.ui_locks == 0 and Game._cursor_locks == 0 and not get_tree().paused, "closing the editor releases them")


## Pass 1: every mesh is drawn by the toon material, with an ink line where
## the manifest asks for one; one key light casts the shadows; every actor
## has a blob shadow.
func _test_toon() -> void:
	check(WorldLook.on_compatibility_renderer(), "the project runs on the Compatibility renderer")
	check(Visual.flag("slime.face_enabled"), "the slime's face is on by default")

	# The slime: the character material, the palette's own shade, an ink line.
	var body := player.get_node("Visual/Slime/Body") as MeshInstance3D
	var jelly := body.material_override as ShaderMaterial
	check(jelly != null and jelly.shader == Toon.CHARACTER_SHADER, "the slime wears the character toon material")
	var lit := Visual.color("palette.slime.body")
	var shade := Visual.color("palette.slime.shade")
	var tint: Color = jelly.get_shader_parameter("shade_tint")
	check(is_equal_approx(tint.r, shade.r / lit.r) and is_equal_approx(tint.b, shade.b / lit.b),
			"its shaded side is the palette's shade colour, not a darker grey")
	var line := jelly.next_pass as ShaderMaterial
	check(line != null and line.shader == Toon.OUTLINE_SHADER and is_equal_approx(line.get_shader_parameter("width_px"), 2.5),
			"and an ink line of the width its manifest entry asks for")
	check((line.get_shader_parameter("line_color") as Color).is_equal_approx(Visual.color("palette.slime.outline")),
			"in the palette's outline colour")

	# The cave: one shared world material; only raised ledges cast shadows.
	var rock: Node = main.level.get_node("Rock")
	var wall := rock.get_node("Wall000") as MeshInstance3D
	var floor_part := rock.get_node("Floor000") as MeshInstance3D
	var stone := wall.material_override as ShaderMaterial
	check(stone != null and stone.shader == Toon.WORLD_SHADER and floor_part.material_override == stone,
			"the rock shares one world toon material")
	check((stone.get_shader_parameter("cap_color") as Color).is_equal_approx(Visual.color("palette.cave.rock_cap")),
			"whose upward faces take the palette's light cap")
	var casters := 0
	for part in rock.get_children():
		if part is MeshInstance3D and part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters += 1
	check(wall.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and casters > 0 and casters < 6,
			"walls and flat floors cast no shadow; raised ledges do (%d)" % casters)
	var plain := _plain_meshes(main)
	check(plain.is_empty(), "no mesh in the game is left on a standard material %s" % str(plain))

	# The key light.
	var key := main.level.get_node("KeyLight") as DirectionalLight3D
	check(key != null and key.shadow_enabled and is_equal_approx(key.rotation_degrees.x, Visual.number("lights.key_pitch")),
			"one key light casts the shadows, aimed by the config")
	Visual.set_value("lights.shadow_enabled", false)
	check(not key.shadow_enabled, "and its shadows can be switched off")
	Visual.reset()

	# Live edits reach materials that were made from config paths.
	Visual.set_value("palette.slime.body", "#FF8040")
	check((jelly.get_shader_parameter("base_color") as Color).is_equal_approx(Color.html("#FF8040")), "a palette edit recolours the slime at once")
	Visual.set_value("outline.scale", 2.0)
	check(is_equal_approx((jelly.next_pass as ShaderMaterial).get_shader_parameter("width_px"), 5.0), "the outline scale widens every line")
	Visual.set_value("outline.enabled", false)
	check(jelly.next_pass == null, "and outlines can be switched off")
	Visual.reset()
	check(jelly.next_pass != null and (jelly.get_shader_parameter("base_color") as Color).is_equal_approx(lit), "resetting restores them")

	# The ink colour rule.
	var red := Color(0.9, 0.3, 0.2)
	var ink := Toon.ink(red)
	check(ink.v < red.v * 0.5 and ink.s >= red.s and ink.h != red.h, "ink is darker and more saturated than its surface, nudged toward blue")
	check(Toon.ink(Color.BLACK).v > 0.05 and Toon.ink(Color.WHITE).s > 0.05, "and is never black or grey")
	var one := Toon.shared({"color": red, "outline_px": 2.0})
	check(one == Toon.shared({"outline_px": 2.0, "color": red}) and one != Toon.shared({"color": red, "outline_px": 3.0}),
			"the same options share one material")

	# Smoothed normals: a cube's three faces agree at each corner.
	var cube := MeshKit.cube()
	var arrays := cube.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var smoothed: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM0]
	var corner := Vector3(0.5, 0.5, 0.5)
	var at_corner: Array[Vector3] = []
	for i in positions.size():
		if positions[i].is_equal_approx(corner):
			at_corner.append(Vector3(smoothed[i * 3], smoothed[i * 3 + 1], smoothed[i * 3 + 2]))
	check(at_corner.size() == 3 and at_corner[0].is_equal_approx(corner.normalized())
			and at_corner[1].is_equal_approx(at_corner[0]) and at_corner[2].is_equal_approx(at_corner[0]),
			"a hard-edged mesh carries one smoothed normal per corner, so its outline does not split")

	# A stand-in whose parts never move is baked into a single mesh.
	var herb := Assets.instantiate("hipokute_herb")
	var other_herb := Assets.instantiate("hipokute_herb")
	var herb_parts := herb.find_children("*", "MeshInstance3D", true, false)
	check(herb_parts.size() == 1 and (herb_parts[0] as MeshInstance3D).mesh == (other_herb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh,
			"a herb is one mesh, shared by every herb")
	check((herb_parts[0] as MeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "and follows its manifest entry's cast_shadow")
	herb.free()
	other_herb.free()

	# A loaded model file gets the same treatment.
	Assets.manifest["test_rock"] = {"id": "test_rock", "file": "tests/fixtures/test_rock.glb", "target_height": 0.5,
			"toonify": true, "outline_px": 2.0, "cast_shadow": true, "placeholder": {"builder": "mote_orb", "seed": 0}}
	var loaded := Assets.instantiate("test_rock")
	var loaded_part := loaded.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var loaded_material := loaded_part.get_active_material(0) as ShaderMaterial
	check(loaded_material != null and loaded_material.shader == Toon.CHARACTER_SHADER and loaded_material.next_pass != null,
			"a model file is given the toon material and an ink line")
	check((loaded_part.mesh as ArrayMesh).surface_get_format(0) & Mesh.ARRAY_FORMAT_CUSTOM0 != 0, "and smoothed normals for that line")
	Assets.manifest["test_rock"]["toonify"] = false
	var untouched := Assets.instantiate("test_rock")
	check(not ((untouched.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_active_material(0) is ShaderMaterial),
			"unless its manifest entry says not to")
	loaded.free()
	untouched.free()
	Assets.reload()

	# A creature: its own materials, a flash when struck, drained when dead.
	var bat := Creature.create("giant_bat")
	main.add_child(bat)
	bat.global_position = player.global_position + Vector3(4.0, 0.3, 0.0)
	bat.home = bat.global_position
	bat.set_physics_process(false)
	var visual := bat._visual as CreatureVisual
	check(visual._body_material.shader == Toon.CHARACTER_SHADER and visual._body_material.next_pass != null, "a creature is toon-shaded and lined")
	bat.take_hit({"amount": 1.0, "damage_type": "impact"})
	check(is_equal_approx(visual._body_material.get_shader_parameter("flash"), 1.0), "a struck creature flashes")
	visual.animate(0.5, 0.0)
	check(is_zero_approx(visual._body_material.get_shader_parameter("flash")), "and the flash fades")
	var alive_color: Color = Toon.options_of(visual._body_material)["color"]

	# Blob shadows: one disc per actor, fainter the higher the actor is.
	var blobs := main.level.get_node("BlobShadows") as BlobShadows
	await frames(3)
	check(blobs.multimesh.visible_instance_count == 2, "the slime and the bat each have a blob shadow")
	var grounded := blobs.strengths[0]
	player.respawn(main.level.spawn_position() + Vector3(0.0, 3.0, 0.0))
	await frames(2)
	var airborne := blobs.strengths[0]
	check(grounded > 0.4 and airborne < grounded - 0.1, "it fades as the slime leaves the ground (%.2f to %.2f)" % [grounded, airborne])
	Visual.set_value("blob_shadow.enabled", false)
	await frames(2)
	check(blobs.multimesh.visible_instance_count == 0, "and can be switched off")
	Visual.reset()

	bat.take_hit({"amount": 9999.0, "damage_type": "impact"})
	var dead_color: Color = Toon.options_of(visual._body_material)["color"]
	check(dead_color != alive_color and dead_color.b >= dead_color.r, "remains drain toward the cave's deep violet, not toward grey")
	await frames(3)
	check(blobs.multimesh.visible_instance_count == 2, "remains keep their blob shadow")
	bat.queue_free()
	await frames(20)


## Names of meshes that are not drawn by one of the project's shaders.
func _plain_meshes(node: Node) -> Array[String]:
	var found: Array[String] = []
	var part := node as MeshInstance3D
	if part != null and part.mesh != null:
		for surface in part.mesh.get_surface_count():
			if not (part.get_active_material(surface) is ShaderMaterial):
				found.append(str(part.get_path()))
				break
	for child in node.get_children():
		found.append_array(_plain_meshes(child))
	return found

