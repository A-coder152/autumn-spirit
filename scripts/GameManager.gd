extends Node

signal stats_changed(leaves, uncollected, happiness, rest)
signal status_message(msg)

var environment = "outside"

var leaves = 0
var uncollected_leaves = 0
var max_uncollected_leaves = 300

var happiness = 80.0
var max_happiness = 100.0

var rest = 80.0
var max_rest = 100

var drain_per_minute = 2.0
var max_leaves_per_minute = 10.0
var leaf_collection_progress = 0.0

var upgrade_unlocks = [false]
var upgrade_costs = [50]

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
	upgrade_unlocks = (data.get("upgrade_unlocks", [false]))
	drain_per_minute = (data.get("drain_per_minute", 2.0))
	max_leaves_per_minute = (data.get("max_leaves_per_minute", 10.0))
	_notify_status("Welcome back")

func _save() -> void:
	var data = {
		"leaves": leaves,
		"uncollected_leaves": uncollected_leaves,
		"happiness": happiness,
		"upgrade_unlocks": upgrade_unlocks,
		"drain_per_minute": drain_per_minute,
		"max_leaves_per_minute": max_leaves_per_minute
	}
	Save.save_game(data)

func drain_timeout() -> void:
	var drain_per_sec = (drain_per_minute / 60.0)
	if upgrade_unlocks[0]:
		drain_per_sec *= 0.9
	happiness = max(0.0, happiness - drain_per_sec)
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)

func generate_timeout() -> void:
	var gen_per_sec = (max_leaves_per_minute / 60.0) * (happiness / max_happiness)
	leaf_collection_progress += gen_per_sec
	if leaf_collection_progress > 1:
		uncollected_leaves += leaf_collection_progress / 1
		leaf_collection_progress -= leaf_collection_progress / 1
		emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)

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

func boost_happiness(amount: float = 10.0) -> void:
	var before = happiness
	happiness = clamp(happiness + amount, 0.0, max_happiness)
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	if happiness > before:
		_notify_status("Happiness increased by (+%d)" % int(amount))

func buy_upgrade(num) -> void:
	if upgrade_unlocks[num]:
		_notify_status("Already unlocked")
		return
	var cost = upgrade_costs[num]
	if leaves < cost:
		_notify_status("Not enough leaves. Need %d." % cost)
		return
	leaves -= cost
	upgrade_unlocks[num] = true
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	_notify_status("Bought upgrade")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()

func _notify_status(msg) -> void:
	status_message.emit(msg)
