extends TestCase
## Visual pipeline (overhaul Pass 0): the visual config, the look it gives
## the level, the asset manager and its stand-ins, and the F4 panel.


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
	Visual.set_value("renderer.antialiasing", "fxaa")
	check(is_equal_approx(environment.fog_density, 0.04), "a live edit reaches the level at once")
	check(get_viewport().screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA and get_viewport().msaa_3d == Viewport.MSAA_DISABLED,
			"including the anti-aliasing mode")
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
	check(rock.name == "TestRock" and is_equal_approx(rock.scale.y, 0.25), "a model file in the manifest is loaded and scaled to its target height")
	check(Assets.warnings.is_empty(), "with no warning")
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

	# The F4 panel.
	var panel: Control = main.get_node("HUD/VisualPanel")
	await tap("debug_visual_panel")
	check(panel.is_open() and panel._rows.get_child_count() == Visual.entries().size(), "F4 opens an editor with a row per setting")
	panel._changed("post.bloom_intensity", 1.2)
	check(is_equal_approx(environment.glow_intensity, 1.2), "editing a row changes the look at once")
	panel._reset_all()
	check(is_equal_approx(environment.glow_intensity, 0.8), "Reset all restores the shipped look")
	await tap("debug_visual_panel")
	check(not panel.is_open() and Game.can_control(), "F4 closes it again")
