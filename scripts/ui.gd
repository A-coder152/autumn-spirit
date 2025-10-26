extends Control

@onready var leaves_label = $topbar/leaves/Label
@onready var collect_btn = $vbox/actions/collect
@onready var happiness_bar = $vbox/happiness/ProgressBar
@onready var feed_btn = $vbox/actions/feed
@onready var shop_btn = $bottombar/shop
@onready var status_label = $status
@onready var shop_window = $shop
@onready var close_shop_btn = $shop/VBoxContainer/leave
@onready var uncollected_bar = $vbox/leafbar/ProgressBar
@onready var rest_bar = $vbox/Rest/ProgressBar
@onready var shop_left_btn = $shop/VBoxContainer/actual/left
@onready var shop_right_btn = $shop/VBoxContainer/actual/right
@onready var shop_buy_btn_list: Array[Button] = [
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy, 
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy2,
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy3,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy2,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy3
]

var shop_view_idx = 0

func _ready() -> void:
	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.status_message.connect(_on_status_message)
	collect_btn.pressed.connect(_on_collect_pressed)
	feed_btn.pressed.connect(_on_feed_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	close_shop_btn.pressed.connect(hide_shop)
	for i in len(shop_buy_btn_list):
		shop_buy_btn_list[i].pressed.connect(func(): _on_buy(i))
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
	shop_view_idx = 0
	refresh_shop_items()
	shop_window.show()

func hide_shop() -> void:
	shop_window.hide()

func _on_buy(num) -> void:
	GameManager.buy_upgrade(num)
	refresh_shop_items()

func _on_autosave_timeout() -> void:
	GameManager.autosave_timeout()

func _on_generate_timeout() -> void:
	GameManager.update_stuff()

func _on_shed_pressed() -> void:
	GameManager.environment = "shed" if GameManager.environment == "outside" else "outside"
	GameManager._save()

func refresh_shop_items() -> void:
	for button in shop_buy_btn_list:
		var idx = shop_view_idx * 6 + shop_buy_btn_list.find(button)
		var item: Item = GameManager.items[idx]
		button.get_child(0).text = item.item_name
		button.get_child(1).get_child(1).text = str(item.cost) if not GameManager.item_unlocks[idx] else "Bought"
		button.tooltip_text = item.desc
		button.get_child(2).texture = item.image

func _on_right_pressed() -> void:
	shop_view_idx = shop_view_idx + 1 if len(GameManager.items) > (shop_view_idx + 2) * 6 else shop_view_idx
	refresh_shop_items()

func _on_left_pressed() -> void:
	shop_view_idx = max(0, shop_view_idx - 1)
	refresh_shop_items()
	
