extends Control

@onready var stats = $vbox
@onready var sprite = $"leaf guy"
@onready var leaves_label: Label = $topbar/leaves/Label
@onready var collect_btn = $vbox/actions/collect
@onready var happiness_bar = $vbox/happiness/ProgressBar
@onready var feed_btn = $vbox/actions/feed
@onready var shop_btn = $bottombar/shop
@onready var status_label = $status
@onready var shop_window = $shop
@onready var farm = $farm
@onready var farm_cont = $farm/VBoxContainer/ScrollContainer/VBoxContainer
@onready var farm_copy = $farm/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer
@onready var close_shop_btn = $shop/VBoxContainer/leave
@onready var uncollected_bar: ProgressBar = $vbox/leafbar/ProgressBar
@onready var settings = $settings
@onready var rest_bar = $vbox/Rest/ProgressBar
@onready var shop_buy_btn_list: Array[Button] = [
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy, 
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy2,
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy3,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy2,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy3
]
@onready var shed = $shed
@onready var shed_btn_list: Array[TextureButton] = [
	$shed/carpet,
	$shed/couch,
	$shed/bed,
	$shed/clock,
	$shed/drawing,
	$shed/mirror
]
@onready var shedboi_btn_list = [
	$shedboi/VBoxContainer/Button,
	$shedboi/VBoxContainer/Button2,
	$shedboi/VBoxContainer/Button3,
	$shedboi/VBoxContainer/Button4,
	$shedboi/VBoxContainer/Button5,
	$shedboi/VBoxContainer/Button6
]
@onready var shedboi = $shedboi
@onready var outside_bg = $bg
@onready var shed_bg = $shed/bg
@onready var resource_app_list = [
	$vbox/leafbar/TextureRect,
	$topbar/leaves/TextureRect,
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy/HBoxContainer/TextureRect,
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy2/HBoxContainer/TextureRect,
	$shop/VBoxContainer/actual/items/HBoxContainer/Buy3/HBoxContainer/TextureRect,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy/HBoxContainer/TextureRect,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy2/HBoxContainer/TextureRect,
	$shop/VBoxContainer/actual/items/HBoxContainer3/Buy3/HBoxContainer/TextureRect
]
@onready var settings_panel = $settings/Panel
@onready var settings_labels = [
	$settings/Panel/VBoxContainer/HBoxContainer/Label,
	$settings/Panel/VBoxContainer/HBoxContainer2/Label,
	$settings/Panel/VBoxContainer/HBoxContainer2/countah
]

var shop_view_idx = 0
var shedboi_positions = [
	Vector2(820, 380),
	Vector2(820, 300),
	Vector2(250, 270),
	Vector2(200, 110),
	Vector2(500, 110),
	Vector2(300, 100)
]
var shedboi_descs = [
	"leaves gained", "max leaves",
	"max happiness", "away happiness drain", "rest happiness",
	"max rest", "outside rest drain", "rest gain", "away rest drain",
	"time before loneliness"
]
var shedboi_num = -1

func _ready() -> void:
	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.status_message.connect(_on_status_message)
	collect_btn.pressed.connect(_on_collect_pressed)
	feed_btn.pressed.connect(_on_feed_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	close_shop_btn.pressed.connect(hide_shop)
	for i in len(shop_buy_btn_list):
		shop_buy_btn_list[i].pressed.connect(func(): _on_buy(i))
	for i in len(shed_btn_list):
		shed_btn_list[i].pressed.connect(func(): run_the_shedboi(i))
	for btn in shedboi_btn_list:
		btn.pressed.connect(func(): change_equipped(btn))
	if GameManager.environment == "shed": _on_shed_pressed()
	apply_theme()
	_on_stats_changed(GameManager.leaves, GameManager.uncollected_leaves, GameManager.happiness, GameManager.rest)

func apply_theme():
	var cur_theme: GameTheme = load(GameManager.theme)
	GameManager.resources = cur_theme.resources
	sprite.texture = cur_theme.main_char
	sprite.scale = cur_theme.main_char_scale if GameManager.environment == "outside" else cur_theme.main_char_scale * 2./3.
	outside_bg.texture = cur_theme.outside_bg
	shed_bg.texture = cur_theme.shed_bg
	for figma in resource_app_list:
		figma.texture = cur_theme.resource
	$topbar/leaves.get_theme_stylebox("panel").bg_color = cur_theme.heavy
	leaves_label.add_theme_color_override("font_color", cur_theme.less_light)
	uncollected_bar.add_theme_color_override("font_color", cur_theme.heavy)
	uncollected_bar.get_theme_stylebox("background").bg_color = cur_theme.normal
	uncollected_bar.get_theme_stylebox("background").border_color = cur_theme.less_light
	uncollected_bar.get_theme_stylebox("fill").bg_color = cur_theme.light
	for sigma in settings_labels:
		sigma.add_theme_color_override("font_color", cur_theme.heavy)
	settings_panel.get_theme_stylebox("panel").bg_color = cur_theme.normal
	settings_panel.get_theme_stylebox("panel").border_color = cur_theme.heavy

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
	GameManager.buy_upgrade(num + shop_view_idx * 6)
	refresh_shop_items()

func _on_autosave_timeout() -> void:
	GameManager.autosave_timeout()

func _on_generate_timeout() -> void:
	GameManager.update_stuff()

func _on_shed_pressed() -> void:
	sprite.position = Vector2(550, 450)
	sprite.scale *= 2./3
	stats.position = Vector2(900, 50)
	stats.scale = Vector2(0.8, 0.8)
	load_shed()
	shed.show()
	GameManager.environment = "shed"
	GameManager._save()

func refresh_shop_items() -> void:
	for button in shop_buy_btn_list:
		var idx = shop_view_idx * 6 + shop_buy_btn_list.find(button)
		var item: Item = GameManager.items[idx]
		button.get_child(0).text = item.item_name
		button.get_child(1).get_child(1).text = str(item.cost) if not GameManager.item_unlocks[idx] else "Bought"
		button.tooltip_text = item.desc
		button.get_child(2).texture = item.image
		button.get_child(2).self_modulate = item.modulate

func _on_right_pressed() -> void:
	shop_view_idx = shop_view_idx + 1 if len(GameManager.items) >= (shop_view_idx + 2) * 6 else shop_view_idx
	refresh_shop_items()

func _on_left_pressed() -> void:
	shop_view_idx = max(0, shop_view_idx - 1)
	refresh_shop_items()

func _on_leave_pressed() -> void:
	sprite.position = Vector2(400, 280)
	sprite.scale *= 3./2
	stats.position = Vector2(592, 160)
	stats.scale = Vector2(1, 1)
	shed.hide()
	shedboi.hide()
	GameManager.environment = "outside"
	GameManager._save()

func run_the_shedboi(num) -> void:
	if shedboi_num == num:
		shedboi_num = -1
		shedboi.hide()
		return
	shedboi_num = num
	for child in shedboi.get_child(0).get_children():
		child.hide()
	shedboi.position = shedboi_positions[num]
	shedboi.show()
	var valid_items = []
	for i in len(GameManager.items):
		if GameManager.item_unlocks[i] and GameManager.items[i].type == num:
			valid_items.append(GameManager.items[i])
	if len(valid_items) == 0:
		shedboi.get_child(0).get_child(6).show()
		return
	for i in len(valid_items):
		var button = shedboi.get_child(0).get_child(i)
		var item = valid_items[i]
		var desc = str(int(item.impact * 100 - 100)) + "% " + shedboi_descs[item.effect]
		button.get_node("HBoxContainer/TextureRect").texture = item.image
		button.get_node("HBoxContainer/TextureRect").modulate = item.modulate
		button.get_node("HBoxContainer/VBoxContainer/Label").text = item.item_name
		button.get_node("HBoxContainer/VBoxContainer/Label2").text = desc
		button.show()

func change_equipped(button):
	if GameManager.equipped_items[shedboi_num]:
		GameManager.undo_item_effect(GameManager.equipped_items[shedboi_num])
	var thingo = shed_btn_list[shedboi_num]
	for item: Item in GameManager.items:
		if item.item_name == button.get_node("HBoxContainer/VBoxContainer/Label").text:
			thingo.texture_normal = item.image
			thingo.self_modulate = item.modulate
			GameManager.apply_item_effect(item)
			GameManager.equipped_items[shedboi_num] = item.resource_path
	shedboi.hide()
	shedboi_num = -1
	GameManager._save()

func load_shed():
	for i in len(GameManager.equipped_items):
		var item = GameManager.equipped_items[i]
		if not item: continue
		item = load(item)
		var thingo = shed_btn_list[i]
		thingo.texture_normal = item.image
		thingo.self_modulate = item.modulate

func _on_switch_theme_pressed() -> void:
	GameManager.theme = "res://themes/spooky_theme.tres" if GameManager.theme == "res://themes/fall_theme.tres" else "res://themes/fall_theme.tres"
	apply_theme()
	GameManager._save()

func _on_leave_settings_pressed() -> void:
	settings.hide()

func _on_settinger_pressed() -> void:
	settings.show()

func _on_timeman_value_changed(value: float) -> void:
	GameManager.time_speed = value
	settings_labels[2].text = "x" + str(int(value * 10) / 10.)

func _on_farm_pressed() -> void:
	farm.show()
	for recipe: Recipe in GameManager.recipes:
		if recipe.location != "Farm": continue
		var recipe_btn = farm_copy.duplicate()
		recipe_btn.get_node("buton/VBoxContainer/title").text = recipe.recipe_name
		recipe_btn.get_node("buton/VBoxContainer/HBoxContainer/input/Label").text = "x" + str(recipe.input_amount) + " " + GameManager.resources[recipe.input].title
		recipe_btn.get_node("buton/VBoxContainer/HBoxContainer/input/TextureRect").texture = load(GameManager.resources[recipe.input].texture)
		recipe_btn.get_node("buton/VBoxContainer/HBoxContainer/output/Label").text = "x" + str(recipe.output_amount) + " " + GameManager.resources[recipe.output].title
		recipe_btn.get_node("buton/VBoxContainer/HBoxContainer/output/TextureRect").texture = load(GameManager.resources[recipe.output].texture)
		recipe_btn.get_node("buton/VBoxContainer/HBoxContainer/TextureRect/timen").text = str(recipe.mins) + "m"
		farm_cont.add_child(recipe_btn)
		recipe_btn.show()

func _on_leave_farm_pressed() -> void:
	farm.hide()
	for child in farm_cont.get_children():
		if child != farm_copy: child.queue_free()
