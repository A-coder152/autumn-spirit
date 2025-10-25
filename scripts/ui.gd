extends Control

@onready var leaves_label = $vbox/leaves/Label
@onready var collect_btn = $vbox/leaves/Button
@onready var happiness_bar = $vbox/happiness/ProgressBar
@onready var feed_btn = $vbox/misc/feed
@onready var shop_btn = $vbox/misc/shop
@onready var status_label = $vbox/status
@onready var shop_window = $shop
@onready var buy_bell_btn = $shop/VBoxContainer/Buy
@onready var close_shop_btn = $shop/VBoxContainer/Leave

func _ready() -> void:
	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.status_message.connect(_on_status_message)
	collect_btn.pressed.connect(_on_collect_pressed)
	feed_btn.pressed.connect(_on_feed_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	buy_bell_btn.pressed.connect(_on_buy_bell_pressed)
	close_shop_btn.pressed.connect(hide_shop)
	_on_stats_changed(GameManager.leaves, GameManager.uncollected_leaves, GameManager.happiness)

func _on_stats_changed(leaves:int, uncollected:int, happiness:float) -> void:
	leaves_label.text = "Leaves: %d (+%d uncollected)" % [leaves, uncollected]
	happiness_bar.value = happiness

func _on_status_message(msg:String) -> void:
	status_label.text = msg

func _on_collect_pressed() -> void:
	GameManager.collect_leaves()

func _on_feed_pressed() -> void:
	GameManager.boost_happiness(10.0)

func _on_shop_pressed() -> void:
	shop_window.show()

func hide_shop() -> void:
	shop_window.hide()

func _on_buy_bell_pressed() -> void:
	GameManager.buy_wind_bell()

func _on_autosave_timeout() -> void:
	GameManager.autosave_timeout()

func _on_generate_timeout() -> void:
	GameManager.generate_timeout()

func _on_drain_timeout() -> void:
	GameManager.drain_timeout()
