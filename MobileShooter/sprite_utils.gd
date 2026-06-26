# sprite_utils.gd
class_name SpriteUtils
extends RefCounted

const PLAYER_TEXTURE       = "res://player.png"
const ENEMY_SCOUT_TEXTURE  = "res://enemy_scout.png"
const ENEMY_DEST_TEXTURE   = "res://enemy_destroyer.png"
const BOSS_TEXTURE         = "res://enemy_boss.png"
const BULLET_TEXTURE       = "res://bullet.png"
const ENEMY_BULLET_TEXTURE = "res://enemy_bullet.png"

static func load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D


static func apply_solid_sprite(sprite: Sprite2D, color: Color, size: int = 8) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	sprite.texture = ImageTexture.create_from_image(img)
