# shop.gd
extends Node2D

const ITEMS := [
	{
		"id": "extra_life",
		"label": "Extra Life",
		"desc": "Start next run with 4 lives instead of 3",
		"cost": 30,
		"max": 1,
		"key": "bought_extra_life",
	},
	{
		"id": "fast_bullet",
		"label": "Turbo Shots",
		"desc": "Bullets travel 40% faster permanently",
		"cost": 50,
		"max": 1,
		"key": "bought_fast_bullet",
	},
	{
		"id": "shield_start",
		"label": "Shield Start",
		"desc": "Begin each run with a one-hit shield",
		"cost": 80,
		"max": 1,
		"key": "bought_shield_start",
	},
]

const CONSUMABLES := [
	{
		"label": "Nuke",
		"desc": "Instantly destroy all enemies on screen right now",
		"cost": 15,
		"key": "consumable_nuke",
		"signal": "nuke_used",
	},
	{
		"label": "Coin Magnet",
		"desc": "Earn 3x coins for the rest of this level",
		"cost": 10,
		"key": "consumable_magnet",
		"signal": "magnet_used",
	},
	{
		"label": "Extra Life (one run)",
		"desc": "Gain +1 life right now, this run only",
		"cost": 25,
		"key": "consumable_life",
		"signal": "life_used",
	},
]

const UPGRADES_PATH := "user://upgrades.cfg"

@onready var _coin_label: Label = $UI/Header/CoinLabel
@onready var _back_btn: Button = $UI/Header/BackButton
@onready var _item_list: VBoxContainer = $UI/ScrollContainer/ItemList

var _cfg := ConfigFile.new()


func _ready() -> void:
	_cfg.load(UPGRADES_PATH)
	_coin_label.text = "🪙 %d" % GameManager.coins
	GameManager.coins_changed.connect(func(c): _coin_label.text = "🪙 %d" % c)
	_back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://MainMenu.tscn"))
	_build_coin_packs()
	_build_list()


func _build_coin_packs() -> void:
	var header := Label.new()
	header.text = "COIN PACKS"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(1, 0.84, 0))
	_item_list.add_child(header)

	var packs := [
		{"label": "500 Coins", "id": IAPManager.PRODUCT_COINS_500, "price": "$0.99"},
		{"label": "2000 Coins", "id": IAPManager.PRODUCT_COINS_2000, "price": "$2.99"},
		{"label": "Remove Ads", "id": IAPManager.PRODUCT_NO_ADS, "price": "$1.99"},
	]
	for pack in packs:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 100)
		var lbl := Label.new()
		lbl.text = pack["label"]
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = pack["price"]
		btn.custom_minimum_size = Vector2(160, 64)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(IAPManager.purchase.bind(pack["id"]))
		IAPManager.purchase_failed.connect(func(pid, _err):
			if pid == pack["id"]:
				btn.text = "Store unavailable"
				await get_tree().create_timer(2.0).timeout
				btn.text = pack["price"]
		)
		row.add_child(lbl)
		row.add_child(btn)
		_item_list.add_child(row)

	var divider := HSeparator.new()
	divider.custom_minimum_size = Vector2(0, 20)
	_item_list.add_child(divider)

	var upg_header := Label.new()
	upg_header.text = "UPGRADES"
	upg_header.add_theme_font_size_override("font_size", 24)
	upg_header.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	_item_list.add_child(upg_header)


func _build_list() -> void:
	for item in ITEMS:
		var owned: bool = bool(_cfg.get_value("owned", item["key"], false))
		var row := _make_row(item, owned)
		_item_list.add_child(row)

	var cons_header := Label.new()
	cons_header.text = "CONSUMABLES  (use anytime)"
	cons_header.add_theme_font_size_override("font_size", 24)
	cons_header.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7))
	_item_list.add_child(cons_header)

	for item in CONSUMABLES:
		var row := _make_consumable_row(item)
		_item_list.add_child(row)


func _make_row(item: Dictionary, owned: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 120)
	row.add_theme_constant_override("separation", 20)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_lbl := Label.new()
	title_lbl.text = item["label"]
	title_lbl.add_theme_font_size_override("font_size", 28)
	info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(desc_lbl)

	row.add_child(info)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 72)
	btn.add_theme_font_size_override("font_size", 22)

	if owned:
		btn.text = "✓ Owned"
		btn.disabled = true
	else:
		btn.text = "🪙 %d" % item["cost"]
		btn.pressed.connect(_on_buy.bind(item, btn))

	row.add_child(btn)
	return row


func _on_buy(item: Dictionary, btn: Button) -> void:
	if GameManager.spend_coins(item["cost"]):
		_cfg.set_value("owned", item["key"], true)
		_cfg.save(UPGRADES_PATH)
		UpgradeManager.reload()
		btn.text = "✓ Owned"
		btn.disabled = true
	else:
		btn.text = "Need 🪙 %d" % item["cost"]
		await get_tree().create_timer(1.2).timeout
		btn.text = "🪙 %d" % item["cost"]


func _make_consumable_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 110)
	row.add_theme_constant_override("separation", 20)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_lbl := Label.new()
	title_lbl.text = item["label"]
	title_lbl.add_theme_font_size_override("font_size", 28)
	info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(desc_lbl)

	row.add_child(info)

	var btn := Button.new()
	btn.text = "🪙 %d" % item["cost"]
	btn.custom_minimum_size = Vector2(160, 72)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_on_buy_consumable.bind(item, btn))
	row.add_child(btn)
	return row


func _on_buy_consumable(item: Dictionary, btn: Button) -> void:
	if GameManager.spend_coins(item["cost"]):
		btn.text = "✓ Used!"
		_apply_consumable(item["key"])
		await get_tree().create_timer(1.0).timeout
		btn.text = "🪙 %d" % item["cost"]
	else:
		btn.text = "Need 🪙 %d" % item["cost"]
		await get_tree().create_timer(1.2).timeout
		btn.text = "🪙 %d" % item["cost"]


func _apply_consumable(key: String) -> void:
	match key:
		"consumable_nuke":
			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e.has_method("_die"):
					e._die()
		"consumable_magnet":
			GameManager.coin_multiplier = 3
			get_tree().create_timer(60.0).timeout.connect(
				func(): GameManager.coin_multiplier = 1
			)
		"consumable_life":
			GameManager.add_life(1)
