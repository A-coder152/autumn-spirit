extends Control

@onready var leaves_label = $topbar/leaves/Label
@onready var collect_btn = $vbox/actions/collect
@onready var happiness_bar = $vbox/happiness/ProgressBar
@onready var feed_btn = $vbox/actions/feed
@onready var shop_btn = $bottombar/shop
@onready var status_label = $status
@onready var shop_window = $shop
@onready var buy_bell_btn = $shop/VBoxContainer/Buy
@onready var close_shop_btn = $shop/VBoxContainer/Leave
@onready var uncollected_bar = $vbox/leafbar/ProgressBar
@onready var rest_bar = $vbox/Rest/ProgressBar

func _ready() -> void:
	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.status_message.connect(_on_status_message)
	collect_btn.pressed.connect(_on_collect_pressed)
	feed_btn.pressed.connect(_on_feed_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	buy_bell_btn.pressed.connect(_on_buy_bell_pressed)
	close_shop_btn.pressed.connect(hide_shop)
	_on_stats_changed(GameManager.leaves, GameManager.uncollected_leaves, GameManager.happiness, GameManager.rest)

func _on_stats_changed(leaves:int, uncollected:int, happiness:float, rest) -> void:
	leaves_label.text = str(leaves)
	happiness_bar.value = happiness
	uncollected_bar.value = uncollected
	rest_bar.value = rest

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
	GameManager.buy_upgrade(0)

func _on_autosave_timeout() -> void:
	GameManager.autosave_timeout()

func _on_generate_timeout() -> void:
	GameManager.update_stuff()

func _on_shed_pressed() -> void:
	GameManager.environment = "shed" if GameManager.environment == "outside" else "outside"
	GameManager._save()
