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

var upgrade_unlocks = [false]
var upgrade_costs = [50]

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
	upgrade_unlocks = (data.get("upgrade_unlocks", [false]))
	away_drain_per_minute = (data.get("away_drain_per_minute", 2.0))
	max_leaves_per_minute = (data.get("max_leaves_per_minute", 10.0))
	last_update = data.get("last_update", Time.get_unix_time_from_system())
	_notify_status("Welcome back")

func _save() -> void:
	var data = {
		"leaves": leaves,
		"uncollected_leaves": uncollected_leaves,
		"happiness": happiness,
		"upgrade_unlocks": upgrade_unlocks,
		"away_drain_per_minute": away_drain_per_minute,
		"max_leaves_per_minute": max_leaves_per_minute,
		"last_update": last_update
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
	if num == 0: away_drain_per_minute *= 0.9
	emit_signal("stats_changed", leaves, uncollected_leaves, happiness, rest)
	_notify_status("Bought upgrade")

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
			uncollected_leaves += leaf_collection_progress / 1
			leaf_collection_progress -= leaf_collection_progress / 1
		rest = max(0, rest - rest_outside_drain_per_minute * normal_mins)
		if mins_over_loneliness > 0:
			var old_happiness = happiness
			happiness = max(0, happiness - away_drain_per_minute * mins_over_loneliness)
			leaf_collection_progress += max_leaves_per_minute * normal_mins * ((happiness + old_happiness) / 2. / max_happiness)
			if leaf_collection_progress > 1:
				uncollected_leaves += leaf_collection_progress / 1
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
