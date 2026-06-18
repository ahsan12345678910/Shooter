class_name SpriteUtils
extends RefCounted

static func make_solid_texture(size: Vector2i, color: Color = Color.WHITE) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


static func apply_solid_sprite(sprite: Sprite2D, color: Color = Color.WHITE) -> void:
	if sprite == null or sprite.texture == null:
		return
	var size := Vector2i(sprite.texture.get_size())
	if size.x < 1 or size.y < 1:
		size = Vector2i(32, 32)
	sprite.texture = make_solid_texture(size, color)
