# iap_manager.gd
# Scaffolding — wire up your platform IAP plugin here.
extends Node

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)

const PRODUCT_COINS_500 = "com.yourname.mobileshooter.coins_500"
const PRODUCT_COINS_2000 = "com.yourname.mobileshooter.coins_2000"
const PRODUCT_NO_ADS = "com.yourname.mobileshooter.remove_ads"


func purchase(product_id: String) -> void:
	push_warning("IAP not implemented yet — wire up plugin for: " + product_id)
	_on_purchase_success(product_id)


func _on_purchase_success(product_id: String) -> void:
	match product_id:
		PRODUCT_COINS_500:
			GameManager.add_coins(500)
		PRODUCT_COINS_2000:
			GameManager.add_coins(2000)
		PRODUCT_NO_ADS:
			_set_no_ads(true)
	purchase_completed.emit(product_id)


func _set_no_ads(value: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("prefs", "no_ads", value)
	cfg.save("user://settings.cfg")


func has_no_ads() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return false
	return bool(cfg.get_value("prefs", "no_ads", false))
