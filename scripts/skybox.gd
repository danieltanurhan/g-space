extends WorldEnvironment
class_name Skybox

# Sets up the WorldEnvironment with a panorama sky texture.
func setup(panorama: Texture2D) -> void:
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = panorama

	var env := Environment.new()
	env.background_mode = Environment.BG_MODE_SKY
	env.sky = sky_material
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	environment = env