extends RefCounted

# These are actual runtime settings for the Compatibility renderer, not promises
# that a device can sustain a particular frame rate or quality level.
const SCALES := [0.70, 0.85, 1.0]
var scale_index := 2
var fxaa := false
var shadows := true
var fps_limit := 60

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	var scale = config.get_value("graphics", "scale_index", scale_index)
	if scale is int and scale >= 0 and scale < SCALES.size():
		scale_index = scale
	var aa = config.get_value("graphics", "fxaa", fxaa)
	if aa is bool:
		fxaa = aa
	var shadow = config.get_value("graphics", "shadows", shadows)
	if shadow is bool:
		shadows = shadow
	var limit = config.get_value("graphics", "fps_limit", fps_limit)
	if limit is int and limit in [30, 60]:
		fps_limit = limit

func apply(viewport: Viewport, sun: DirectionalLight3D) -> void:
	viewport.scaling_3d_scale = SCALES[scale_index]
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
	sun.shadow_enabled = shadows
	Engine.max_fps = fps_limit

func save_settings() -> bool:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("graphics", "scale_index", scale_index)
	config.set_value("graphics", "fxaa", fxaa)
	config.set_value("graphics", "shadows", shadows)
	config.set_value("graphics", "fps_limit", fps_limit)
	return config.save("user://settings.cfg") == OK
