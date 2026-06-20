# upgrade_manager.gd
extends Node

const UPGRADES_PATH := "user://upgrades.cfg"

var extra_life: bool = false
var fast_bullet: bool = false
var shield_start: bool = false


func _ready() -> void:
	reload()


func reload() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(UPGRADES_PATH) != OK:
		return
	extra_life = bool(cfg.get_value("owned", "bought_extra_life", false))
	fast_bullet = bool(cfg.get_value("owned", "bought_fast_bullet", false))
	shield_start = bool(cfg.get_value("owned", "bought_shield_start", false))
