# iap_manager.gd
# Scaffolding — wire up your platform IAP plugin here.
extends Node

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)

const PRODUCT_COINS_500 = "com.yourname.mobileshooter.coins_500"
const PRODUCT_COINS_2000 = "com.yourname.mobileshooter.coins_2000"
const PRODUCT_NO_ADS = "com.yourname.mobileshooter.remove_ads"


func purchase(product_id: String) -> void:
	# --- PLATFORM PLUGIN WIRING GOES HERE ---
	# Android (GodotGooglePlayBilling plugin):
	#   billing.purchase(product_id)
	#   Connect billing.purchases_updated signal to _on_purchase_success()
	#
	# iOS (GodotIOSInAppPurchases plugin):
	#   InAppPurchases.purchase({"productId": product_id})
	#   Connect InAppPurchases.product_purchase_completed to _on_purchase_success()
	#
	# Until plugin is installed, show a message instead of giving free coins:
	push_error("IAP plugin not installed. Product: " + product_id + " — no coins awarded.")
	purchase_failed.emit(product_id, "IAP plugin not configured")
	# DO NOT call _on_purchase_success() here — that gives coins for free.


func on_platform_purchase_verified(product_id: String) -> void:
	# Called by the platform plugin ONLY after payment is verified.
	# Wire your plugin's success callback to call this function.
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
