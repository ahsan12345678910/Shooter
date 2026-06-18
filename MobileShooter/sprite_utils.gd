extends RefCounted

static func make_solid_texture(size: Vector2i, color: Color = Color.WHITE) -> ImageTexture:
	var image := Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


static func apply_solid_sprite(sprite: Sprite2D, color: Color = Color.WHITE, fallback_size: Vector2i = Vector2i(32, 32)) -> void:
	if sprite == null:
		return

	var size := fallback_size
	if sprite.texture != null:
		var tex_size := Vector2i(sprite.texture.get_size())
		if tex_size.x > 0 and tex_size.y > 0:
			size = tex_size

	sprite.texture = make_solid_texture(size, color)
