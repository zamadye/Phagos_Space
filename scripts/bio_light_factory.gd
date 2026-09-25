class_name BioLightFactory
extends RefCounted
## Reuses one small radial texture across all PointLight2D emitters. This keeps biological
## lighting expressive without allocating a unique texture for every vein or node.

static var _radial_texture: Texture2D

static func create_point_light(light_color: Color, energy: float, radius: float, z_layer: int = 0) -> PointLight2D:
    var light := PointLight2D.new()
    light.name = "BioPointLight"
    light.texture = _get_radial_texture()
    light.color = light_color
    light.energy = energy
    light.texture_scale = radius / 128.0
    light.blend_mode = Light2D.BLEND_MODE_ADD
    light.shadow_enabled = false
    light.z_index = z_layer
    return light

static func _get_radial_texture() -> Texture2D:
    if _radial_texture != null:
        return _radial_texture
    var size := 128
    var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var center := Vector2(size - 1, size - 1) * 0.5
    for y in range(size):
        for x in range(size):
            var distance := Vector2(x, y).distance_to(center) / (size * 0.5)
            var alpha := pow(maxf(0.0, 1.0 - distance), 2.4)
            image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
    _radial_texture = ImageTexture.create_from_image(image)
    return _radial_texture
