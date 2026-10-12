extends Node
## AdManager - Google AdMob integration (Poing AdMob Plugin v5)
## Banner (bottom), Interstitial (on level complete), Rewarded (add tube)

# Google AdMob Ad Unit IDs
const ADMOB_APP_ID: String = "ca-app-pub-1852108665659812~2158593116"
const BANNER_AD_ID: String = "ca-app-pub-1852108665659812/2094269072"
const INTERSTITIAL_AD_ID: String = "ca-app-pub-1852108665659812/5841942392"
const REWARDED_AD_ID: String = "ca-app-pub-1852108665659812/3945397639"
const REWARDED_INTERSTITIAL_AD_ID: String = "ca-app-pub-3940256099942544/5354046379"

static var instance: Node
static var is_initialized: bool = false
var _plugin_available: bool = false

signal rewarded_video_completed
signal rewarded_video_unavailable(message: String)
signal rewarded_interstitial_completed
signal rewarded_interstitial_unavailable(message: String)

# Cached loaded ad objects
var _banner_view_bottom = null
var _interstitial_ad = null
var _rewarded_ad = null
var _rewarded_interstitial_ad = null

# REQUIRED: Keep callbacks alive so Godot doesn't garbage collect them!
var _init_listener = null
var _banner_cb = null
var _interstitial_cb = null
var _rewarded_cb = null
var _reward_listener = null
var _rewarded_interstitial_cb = null
var _rewarded_interstitial_content_cb = null
var _rewarded_interstitial_listener = null

var banner_id: String = BANNER_AD_ID
var interstitial_id: String = INTERSTITIAL_AD_ID
var rewarded_id: String = REWARDED_AD_ID
var rewarded_interstitial_id: String = REWARDED_INTERSTITIAL_AD_ID

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	print("[AdManager] _ready - checking for MobileAds plugin...")
	if OS.get_name() == "Android":
		_plugin_available = true
		
		# Auto-inject test IDs in debug builds to prevent No Fill errors
		if OS.has_feature("debug"):
			print("[AdManager] Debug build detected: Using Test IDs")
			banner_id = "ca-app-pub-3940256099942544/6300978111"
			interstitial_id = "ca-app-pub-3940256099942544/1033173712"
			rewarded_id = "ca-app-pub-3940256099942544/5224354917"
		rewarded_interstitial_id = "ca-app-pub-3940256099942544/5354046379"
			
		print("[AdManager] Running on Android - initializing AdMob with banner: ", banner_id)
		_init_admob()
	else:
		print("[AdManager] Not on Android - ads disabled (desktop/editor mode)")

func _init_admob() -> void:
	if not _plugin_available:
		return
	_init_listener = OnInitializationCompleteListener.new()
	_init_listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		print("[AdManager] MobileAds native initialization complete!")
		is_initialized = true
		_load_banner_bottom()
		_load_interstitial()
		_load_rewarded()
	
	MobileAds.initialize(_init_listener)
	print("[AdManager] MobileAds.initialize() requested")

# =================== BANNER (BOTTOM ONLY) ===================

func _load_banner_bottom() -> void:
	if not is_initialized or _banner_view_bottom != null:
		return

	_banner_view_bottom = AdView.new(banner_id, AdSize.BANNER, AdPosition.BOTTOM)
	_banner_cb = AdListener.new()
	_banner_cb.on_ad_loaded = func():
		print("[AdManager] Bottom Banner loaded and shown!")
		if _banner_view_bottom and _banner_view_bottom.has_method("show"):
			_banner_view_bottom.show()
	_banner_cb.on_ad_failed_to_load = func(_err):
		print("[AdManager] Bottom Banner failed to load: ", _err)
	_banner_view_bottom.ad_listener = _banner_cb
	_banner_view_bottom.load_ad(AdRequest.new())

func show_banner() -> void:
	if GameState.ads_removed:
		hide_banner()
		return
	if not _plugin_available:
		return
	if _banner_view_bottom == null:
		if is_initialized:
			_load_banner_bottom()
	elif _banner_view_bottom.has_method("show"):
		_banner_view_bottom.show()

func hide_banner() -> void:
	if _banner_view_bottom and _banner_view_bottom.has_method("hide"):
		_banner_view_bottom.hide()

# =================== INTERSTITIAL ===================

func _load_interstitial() -> void:
	if not is_initialized: return

	var loader := InterstitialAdLoader.new()
	_interstitial_cb = InterstitialAdLoadCallback.new()

	_interstitial_cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_ad = ad
		print("[AdManager] Interstitial Ad loaded!")
		ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
			_interstitial_ad = null
		_load_interstitial()
		ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_err):
			_interstitial_ad = null
		_load_interstitial()

	_interstitial_cb.on_ad_failed_to_load = func(_err) -> void:
		_interstitial_ad = null
		print("[AdManager] Interstitial failed to load: ", _err)

	loader.load(interstitial_id, AdRequest.new(), _interstitial_cb)

func show_interstitial() -> void:
	if GameState.ads_removed: return
	if not _plugin_available: return
	if _interstitial_ad:
		_interstitial_ad.show()
	else:
		if is_initialized:
			_load_interstitial()

# =================== REWARDED ===================

func _load_rewarded() -> void:
	if not is_initialized: return

	var loader := RewardedAdLoader.new()
	_rewarded_cb = RewardedAdLoadCallback.new()

	_rewarded_cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_ad = ad
		print("[AdManager] Rewarded Ad loaded!")
		ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
			_rewarded_ad = null
			_load_rewarded()
		ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_err):
			_rewarded_ad = null
			_load_rewarded()

	_rewarded_cb.on_ad_failed_to_load = func(_err) -> void:
		_rewarded_ad = null
		print("[AdManager] Rewarded Ad failed to load: ", _err)

	loader.load(rewarded_id, AdRequest.new(), _rewarded_cb)

func show_rewarded_video() -> bool:
	if not _plugin_available:
		rewarded_video_unavailable.emit("Rewarded ads are available on Android builds only.")
		return false

	if _rewarded_ad:
		var user_rewarded: Array[bool] = [false]
		_reward_listener = OnUserEarnedRewardListener.new()
		_reward_listener.on_user_earned_reward = func(_item):
			user_rewarded[0] = true
		_rewarded_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
			_rewarded_ad = null
			_load_rewarded()
			if user_rewarded[0]:
				rewarded_video_completed.emit()
		_rewarded_ad.show(_reward_listener)
		return true

	rewarded_video_unavailable.emit("The rewarded ad is still loading. Please try again shortly.")
	if is_initialized:
		_load_rewarded()
	return false
# =================== REWARDED INTERSTITIAL ===================

func _load_rewarded_interstitial() -> void:
	if not is_initialized or _rewarded_interstitial_ad:
		return
	var loader := RewardedInterstitialAdLoader.new()
	_rewarded_interstitial_cb = RewardedInterstitialAdLoadCallback.new()
	_rewarded_interstitial_cb.on_ad_loaded = func(ad: RewardedInterstitialAd) -> void:
		_rewarded_interstitial_ad = ad
		_rewarded_interstitial_content_cb = FullScreenContentCallback.new()
		_rewarded_interstitial_content_cb.on_ad_dismissed_full_screen_content = func():
			_destroy_rewarded_interstitial()
		_rewarded_interstitial_content_cb.on_ad_failed_to_show_full_screen_content = func(_error):
			_destroy_rewarded_interstitial()
		ad.full_screen_content_callback = _rewarded_interstitial_content_cb
	_rewarded_interstitial_cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_interstitial_ad = null
		push_warning("Rewarded interstitial failed to load: %s" % error.message)
	loader.load(rewarded_interstitial_id, AdRequest.new(), _rewarded_interstitial_cb)

func show_rewarded_interstitial() -> bool:
	if not _plugin_available:
		rewarded_interstitial_unavailable.emit("Rewarded interstitials are available on Android builds only.")
		return false
	if not _rewarded_interstitial_ad:
		rewarded_interstitial_unavailable.emit("The rewarded interstitial is still loading. Please try again shortly.")
		if is_initialized:
			_load_rewarded_interstitial()
		return false
	_rewarded_interstitial_listener = OnUserEarnedRewardListener.new()
	_rewarded_interstitial_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		rewarded_interstitial_completed.emit()
	_rewarded_interstitial_ad.show(_rewarded_interstitial_listener)
	return true

func _destroy_rewarded_interstitial() -> void:
	if _rewarded_interstitial_ad:
		_rewarded_interstitial_ad.destroy()
		_rewarded_interstitial_ad = null
