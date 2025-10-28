extends Node

signal stats_changed(leaves, uncollected, happiness, rest)
signal status_message(msg)

var environment = "outside"

var leaves = 0
var uncollected_leaves = 0
var max_uncollected_leaves = 300
var max_leaves_per_minute = 10.0
var leaf_collection_progress = 0.0

var happiness = 80.0
var max_happiness = 100.0
var away_drain_per_minute = 100. / 480.
var happiness_rest_per_minute = 0.1

var rest = 80.0
var max_rest = 100
var rest_outside_drain_per_minute = 100. / 480.
var rest_shed_gain_per_minute = 100. / 360.
var rest_nothappy_drain_per_minute = 100. / 480.

var items = [
	preload("res://items/mat1.tres"),
	preload("res://items/couch1.tres"),
	preload("res://items/couch2.tres"),
	preload("res://items/mat2.tres"),
	preload("res://items/couch3.tres"),
	preload("res://items/mat3.tres"),
	preload("res://items/mat4.tres"),
	preload("res://items/couch4.tres"),
	preload("res://items/mat5.tres"),
	preload("res://items/couch5.tres"),
	preload("res://items/mat6.tres"),
	preload("res://items/couch6.tres")
]
var item_unlocks = [
	false, false, false, false, false, false,
	false, false, false, false, false, false
]
var equipped_items = [null, null, null, null, null, null]

var last_update
var loneliness_time = 480

func _ready() -> void:
	_load_or_init()
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)

func _load_or_init() -> void:
	var data = Save.load_game()
	if data.is_empty():
		_notify_status("Welcome")
		return
	leaves = (data.get("leaves", 0))
	uncollected_leaves = (data.get("uncollected_leaves", 0))
	happiness = (data.get("happiness", 80.0))
	item_unlocks = (data.get("item_unlocks", item_unlocks))
	away_drain_per_minute = (data.get("away_drain_per_minute", 2.0))
	max_leaves_per_minute = (data.get("max_leaves_per_minute", 10.0))
	last_update = data.get("last_update", Time.get_unix_time_from_system())
	environment = data.get("environment", "outside")
	max_uncollected_leaves = data.get("max_uncollected_leaves", max_uncollected_leaves)
	max_happiness = data.get("max_happiness", max_happiness)
	happiness_rest_per_minute = data.get("happiness_rest_per_minute", happiness_rest_per_minute)
	max_rest = data.get("max_rest", max_rest)
	rest = data.get("rest", 80.0)
	rest_outside_drain_per_minute = data.get("rest_outside_drain_per_minute", rest_outside_drain_per_minute)
	rest_shed_gain_per_minute = data.get("rest_shed_gain_per_minute", rest_shed_gain_per_minute)
	rest_nothappy_drain_per_minute = data.get("rest_nothappy_drain_per_minute", rest_nothappy_drain_per_minute)
	loneliness_time = data.get("loneliness_time", loneliness_time)
	equipped_items = data.get("equipped_items", equipped_items)
	_notify_status("Welcome back")

func _save() -> void:
	var data = {
		"leaves": leaves,
		"uncollected_leaves": uncollected_leaves,
		"happiness": happiness,
		"item_unlocks": item_unlocks,
		"away_drain_per_minute": away_drain_per_minute,
		"max_leaves_per_minute": max_leaves_per_minute,
		"last_update": last_update,
		"rest": rest,
		"environment": environment,
		"max_uncollected_leaves": max_uncollected_leaves,
		"max_happiness": max_happiness,
		"happiness_rest_per_minute": happiness_rest_per_minute,
		"max_rest": max_rest,
		"rest_outside_drain_per_minute": rest_outside_drain_per_minute,
		"rest_shed_gain_per_minute": rest_shed_gain_per_minute,
		"rest_nothappy_drain_per_minute": rest_nothappy_drain_per_minute,
		"loneliness_time": loneliness_time,
		"equipped_items": equipped_items
	}
	Save.save_game(data)

func autosave_timeout() -> void:
	_save()

func collect_leaves() -> void:
	if uncollected_leaves <= 0:
		_notify_status("No uncollected leaves")
		return
	leaves += uncollected_leaves
	uncollected_leaves = 0
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	_notify_status("Leaves collected")
	_save()

func boost_happiness(amount: float = 10.0) -> void:
	var before = happiness
	happiness = clamp(happiness + amount, 0.0, max_happiness)
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	if happiness > before:
		_notify_status("Happiness increased by (+%d)" % int(amount))

func buy_upgrade(num) -> void:
	var item: Item = items[num]
	if item_unlocks[num]:
		_notify_status("Already unlocked")
		return
	if leaves < item.cost:
		_notify_status("Not enough leaves. Need %d." % item.cost)
		return
	leaves -= item.cost
	item_unlocks[num] = true
	#apply_item_effect(item)
	_save()
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	_notify_status("Bought upgrade")

func apply_item_effect(item):
	match item.effect:
		item.effects.LEAVES_GAIN:
			max_leaves_per_minute *= item.impact
		item.effects.LEAVES_MAX:
			max_uncollected_leaves *= item.impact
		item.effects.HAPPINESS_MAX:
			max_happiness *= item.impact
		item.effects.HAPPINESS_DRAIN:
			away_drain_per_minute *= item.impact
		item.effects.HAPPINESS_REST:
			happiness_rest_per_minute *= item.impact
		item.effects.REST_MAX:
			max_rest *= item.impact
		item.effects.REST_DRAIN:
			rest_outside_drain_per_minute *= item.impact
		item.effects.REST_GAIN:
			rest_shed_gain_per_minute *= item.impact
		item.effects.REST_UNHAPPY:
			rest_nothappy_drain_per_minute *= item.impact
		item.effects.LONELINESS_TIME:
			loneliness_time *= item.impact

func undo_item_effect(item):
	if item is String: item = load(item)
	match item.effect:
		item.effects.LEAVES_GAIN:
			max_leaves_per_minute /= item.impact
		item.effects.LEAVES_MAX:
			max_uncollected_leaves /= item.impact
		item.effects.HAPPINESS_MAX:
			max_happiness /= item.impact
		item.effects.HAPPINESS_DRAIN:
			away_drain_per_minute /= item.impact
		item.effects.HAPPINESS_REST:
			happiness_rest_per_minute /= item.impact
		item.effects.REST_MAX:
			max_rest /= item.impact
		item.effects.REST_DRAIN:
			rest_outside_drain_per_minute /= item.impact
		item.effects.REST_GAIN:
			rest_shed_gain_per_minute /= item.impact
		item.effects.REST_UNHAPPY:
			rest_nothappy_drain_per_minute /= item.impact
		item.effects.LONELINESS_TIME:
			loneliness_time /= item.impact

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()

func _notify_status(msg) -> void:
	status_message.emit(msg)

func update_stuff() -> void:
	var now = Time.get_unix_time_from_system()
	var delta_mins = (now - last_update) / 60.
	var normal_mins = min(delta_mins, loneliness_time)
	var mins_over_loneliness = min(delta_mins - loneliness_time, loneliness_time)
	var you_r_dead = delta_mins - loneliness_time * 2
	if environment == "outside":
		leaf_collection_progress += max_leaves_per_minute * normal_mins * (happiness / max_happiness)
		if leaf_collection_progress > 1:
			uncollected_leaves = min(max_uncollected_leaves, uncollected_leaves + leaf_collection_progress / 1)
			leaf_collection_progress -= leaf_collection_progress / 1
		rest = max(0, rest - rest_outside_drain_per_minute * normal_mins)
		if mins_over_loneliness > 0:
			var old_happiness = happiness
			happiness = max(0, happiness - away_drain_per_minute * mins_over_loneliness)
			leaf_collection_progress += max_leaves_per_minute * normal_mins * ((happiness + old_happiness) / 2. / max_happiness)
			if leaf_collection_progress > 1:
				uncollected_leaves = min(max_uncollected_leaves, uncollected_leaves + leaf_collection_progress / 1)
				leaf_collection_progress -= leaf_collection_progress / 1
	else:
		happiness = min(happiness + happiness_rest_per_minute * normal_mins, 100)
		rest = min(100, rest + rest_shed_gain_per_minute * normal_mins)
		if mins_over_loneliness > 0:
			happiness = max(0, happiness - away_drain_per_minute * mins_over_loneliness)
		if you_r_dead > 0: 
			rest = max(0, rest - you_r_dead * rest_nothappy_drain_per_minute)
	
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	last_update = now
