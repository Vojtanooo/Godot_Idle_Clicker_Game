extends Control

var points: float = 0
var points_per_click: int = 1
var auto_clicks_per_second: int = 0
var points_per_second: float = 0.0
var generator_buttons = []
var upgrade_buttons = []
var prestige_points: int = 0
var prestige_multiplier: float = 1.0
var click_bonus: int = 0
var idle_multiplier: float = 1.0
var price_discount: float = 0.0

@onready var points_label = $MarginContainer/VBox/TopBar/PointsLabel
@onready var pps_label = $MarginContainer/VBox/TopBar/RightStats/PointsPerSecondLabel
@onready var prestige_info_label = $MarginContainer/VBox/TopBar/RightStats/PrestigeInfoLabel
@onready var click_button = $MarginContainer/VBox/ClickSection/ClickButton
@onready var upgrades_box = $MarginContainer/VBox/UpgradesBox
@onready var prestige_button = $MarginContainer/VBox/PrestigeButtons/PrestigeButton
@onready var prestige_shop_button = $MarginContainer/VBox/PrestigeButtons/PrestigeShopButton
@onready var achievements_button = $MarginContainer/VBox/PrestigeButtons/AchievementsButton
@onready var offline_dialog = $OfflineDialog

var generators = [
	{"name": "MiniBot", "base_price": 50, "gain": 0.5, "count": 0, "level": 1},
	{"name": "Malý robot", "base_price": 100, "gain": 1, "count": 0, "level": 1},
	{"name": "Velký robot", "base_price": 500, "gain": 5, "count": 0, "level": 1},
	{"name": "Hyper robot", "base_price": 2000, "gain": 20, "count": 0, "level": 1},
	{"name": "AI Robot", "base_price": 10000, "gain": 100, "count": 0, "level": 1}
]

var achievements = [
	{"name": "První klik!", "desc": "Získej první bod", "check": func(): return points >= 1, "unlocked": false},
	{"name": "Robotí startup", "desc": "Kup první generátor", "check": func(): return generators[0].count >= 1, "unlocked": false},
	{"name": "Robotí impérium", "desc": "Získej 100 robotů", "check": func():
		var total = 0
		for gen in generators:
			total += gen.count
		return total >= 100, "unlocked": false},
	{"name": "Prestige poprvé", "desc": "Použij prestige", "check": func(): return prestige_points > 0, "unlocked": false},
	{"name": "Klikací maniak", "desc": "Získej 1000 bodů klikáním", "check": func(): return points_per_click > 10, "unlocked": false},
	{"name": "Bodová banka", "desc": "Nasbírej 10 000 bodů", "check": func(): return points >= 10000, "unlocked": false},
	{"name": "Elita robotů", "desc": "Vylepši některého robota na lvl 5", "check": func():
		for gen in generators:
			if gen.level >= 5:
				return true
		return false, "unlocked": false},
	{"name": "Prestige veterán", "desc": "Získej 10 prestige bodů", "check": func(): return prestige_points >= 10, "unlocked": false},
	{"name": "Idle investor", "desc": "Získej 100 bodů pasivně", "check": func(): return idle_multiplier > 1.5, "unlocked": false},
	{"name": "Auto-click master", "desc": "Získej alespoň 5 auto-clicků", "check": func(): return auto_clicks_per_second >= 5, "unlocked": false},
	{
	"name": "Bodový mistr",
	"desc_levels": [
		"Získej 10 000 bodů",
		"Získej 100 000 bodů",
		"Získej 1 000 000 bodů"
	],
	"targets": [10000, 100000, 1000000],
	"current_level": 0,
	"unlocked_levels": []
}
]

func _ready():
	load_game()
	click_button.pressed.connect(on_click)
	prestige_button.pressed.connect(do_prestige)
	prestige_shop_button.pressed.connect(show_prestige_shop)
	achievements_button.pressed.connect(show_achievements_list)
	create_upgrade_buttons()
	start_idle_timer()
	update_ui()
	
func on_click():
	points += (points_per_click + click_bonus) * prestige_multiplier
	check_achievements()
	check_progressive_achievements()
	update_upgrade_button_texts() 
	update_ui()

func update_ui():
	points_label.text = "Body: " + str(points) + " | Prestige: " + str(prestige_points)
	pps_label.text = "Příjem: +%.1f /s (idle)" % (points_per_second * prestige_multiplier * idle_multiplier)
	pps_label.text += "\nAuto-clicky: +%d /s" % auto_clicks_per_second
	prestige_info_label.text = "Prestige body: %d (x%.1f)" % [prestige_points, prestige_multiplier]
	prestige_button.disabled = points < 1000
	prestige_shop_button.disabled = prestige_points < 1

func check_achievements():
	for achievement in achievements:
		if "check" in achievement:
			if not achievement.unlocked and achievement.check.call():
				achievement.unlocked = true
				show_achievement_popup(achievement.name, achievement.desc)

func check_progressive_achievements():
	for achievement in achievements:
		if "targets" in achievement:
			var level = achievement.current_level
			if level < achievement.targets.size() and points >= achievement.targets[level]:
				achievement.unlocked_levels.append(level)
				show_achievement_popup(
					achievement.name + " – úroveň " + str(level + 1),
					achievement.desc_levels[level]
				)
				achievement.current_level += 1

func show_achievement_popup(name: String, desc: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Achievement odemčen!"
	dialog.dialog_text = "%s\n%s" % [name, desc]
	dialog.min_size = Vector2(300, 150)
	add_child(dialog)
	dialog.popup_centered()

func show_achievements_list():
	var dialog = AcceptDialog.new()
	dialog.title = "Achievementy"
	dialog.dialog_text = ""
	dialog.min_size = Vector2(400, 300)

	for ach in achievements:
		if "targets" in ach:
			for i in range(ach.desc_levels.size()):
				var status = "✅" if i in ach.unlocked_levels else "❌"
				dialog.dialog_text += "%s %s – %s\n" % [status, ach.name, ach.desc_levels[i]]
		else:
			var status = "✅" if ach.has("unlocked") and ach.unlocked else "❌"
			dialog.dialog_text += "%s %s – %s\n" % [status, ach.name, ach.desc]

	add_child(dialog)
	dialog.popup_centered()

func create_upgrade_buttons():
	generator_buttons.clear()
	upgrade_buttons.clear()

	for child in upgrades_box.get_children():
		child.queue_free()

	for i in range(generators.size()):
		var gen_btn = Button.new()
		gen_btn.pressed.connect(Callable(self, "on_generator_button_pressed").bind(i))
		upgrades_box.add_child(gen_btn)
		generator_buttons.append(gen_btn)

		var upgrade_btn = Button.new()
		upgrade_btn.pressed.connect(Callable(self, "on_upgrade_generator_pressed").bind(i))
		upgrades_box.add_child(upgrade_btn)
		upgrade_buttons.append(upgrade_btn)

	update_upgrade_button_texts()

func update_single_button_texts(i: int):
	var gen = generators[i]
	var price = int((gen.base_price + gen.count * gen.base_price) * (1.0 - price_discount))
	var gain = gen.count * gen.gain * gen.level
	generator_buttons[i].text = "%s – lvl %d – Cena: %d bodů – +%.1f/s" % [gen.name, gen.count, price, gain]
	generator_buttons[i].disabled = points < price

	var upgrade_price = 2 * (gen.level + 1)
	upgrade_buttons[i].text = "Vylepšit za %d prestige" % upgrade_price
	upgrade_buttons[i].disabled = prestige_points < upgrade_price

func update_upgrade_button_texts():
	points_per_second = 0
	for i in range(generators.size()):
		update_single_button_texts(i)
		var gen = generators[i]
		points_per_second += gen.count * gen.gain * gen.level

func on_generator_button_pressed(i: int):
	buy_generator(i)
	update_upgrade_button_texts()

func on_upgrade_generator_pressed(i: int):
	upgrade_generator(i)
	update_upgrade_button_texts()

func upgrade_generator(i: int):
	var gen = generators[i]
	var upgrade_price = 1 * (gen.level + 1)
	if prestige_points >= upgrade_price:
		prestige_points -= upgrade_price
		gen.level += 1
		generators[i] = gen
		create_upgrade_buttons()
		update_ui()

func buy_generator(i: int):
	var gen = generators[i]
	var price = (gen.base_price + (gen.count * gen.base_price)) * (1.0 - price_discount)
	price = int(price)
	if points >= price:
		points -= price
		gen.count += 1
		points_per_second += gen.gain
		generators[i] = gen
		check_achievements()
		check_progressive_achievements()
		update_upgrade_button_texts()
		update_ui()

func buy_click_power():
	if points >= 50:
		points -= 50
		points_per_click += 1
		update_ui()

func buy_idle_generator():
	var price = 100 + points_per_second * 50
	if points >= price:
		points -= price
		points_per_second += 1
		update_ui()

func start_idle_timer():
	var idle_timer = Timer.new()
	idle_timer.wait_time = 1.0
	idle_timer.timeout.connect(on_idle_tick)
	add_child(idle_timer)
	idle_timer.start()
	
	var auto_click_timer = Timer.new()
	auto_click_timer.wait_time = 1.0
	auto_click_timer.timeout.connect(on_auto_click)
	add_child(auto_click_timer)
	auto_click_timer.start()

func on_idle_tick():
	points += points_per_second * prestige_multiplier * idle_multiplier
	update_upgrade_button_texts()
	update_ui()

func do_prestige():
	if points >= 1000:
		var gained = int(points / 1000)
		prestige_points += gained
		prestige_multiplier = 1.0 + (prestige_points * 0.1)
		points = 0
		points_per_click = 1
		points_per_second = 0
		click_bonus = 0
		idle_multiplier = 1.0
		price_discount = 0.0
		for i in generators.size():
			generators[i].count = 0
		check_progressive_achievements()
		update_upgrade_button_texts()
		check_achievements()
		update_ui()
		print("Prestige +%d, celkem: %d" % [gained, prestige_points])
	else:
		print("Musíš mít aspoň 1000 bodů pro prestige!")

func show_prestige_shop():
	if prestige_points < 1:
		return

	var upgrades = [
		{ "name": "+1 klik (1 bod)", "cost": 1, "type": "click_bonus" },
		{ "name": "+10% idle (1 body)", "cost": 1, "type": "idle_multiplier" },
		{ "name": "Zlevnění robotů o 5% (1 body)", "cost": 1, "type": "price_discount" },
		{ "name": "+1 auto-click/s (2 body)", "cost": 2, "type": "auto_click" },
		{ "name": "+5% celkový příjem (2 body)", "cost": 2, "type": "prestige_multiplier" }
	]

	upgrades.shuffle()
	var selected = upgrades.slice(0, 3)

	# Vytvoř dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = ""
	dialog.title = "Obchod za Prestige"
	dialog.min_size = Vector2(400, 250)

	# Vytvoř VBoxContainer pro tlačítka
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(350, 200)
	dialog.add_child(vbox)

	# Přidej tlačítka
	for upgrade in selected:
		var btn = Button.new()
		btn.text = upgrade.name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			if prestige_points >= upgrade.cost:
				apply_upgrade(upgrade.type)
				prestige_points -= upgrade.cost
				update_ui()
				dialog.queue_free()
		)
		vbox.add_child(btn)

	add_child(dialog)
	dialog.popup_centered()


func apply_upgrade(upgrade_type: String):
	match upgrade_type:
		"click_bonus":
			click_bonus += 1
		"idle_multiplier":
			idle_multiplier += 0.1
		"price_discount":
			price_discount += 0.05
			update_upgrade_button_texts()
		"auto_click":
			auto_clicks_per_second += 1
		"prestige_multiplier":
			prestige_multiplier += 0.05

func get_utc_unix_time():
	var dt = Time.get_datetime_dict_from_system()
	return Time.get_unix_time_from_datetime_dict(dt)

func save_game():
	var config = ConfigFile.new()
	for i in generators.size():
		config.set_value("generators", "gen_" + str(i), generators[i].count)
	config.set_value("player", "points", points)
	config.set_value("player", "points_per_click", points_per_click)
	config.set_value("player", "points_per_second", points_per_second)
	config.set_value("prestige", "points", prestige_points)
	config.set_value("prestige", "multiplier", prestige_multiplier)
	config.set_value("prestige", "click_bonus", click_bonus)
	config.set_value("prestige", "idle_multiplier", idle_multiplier)
	config.set_value("prestige", "price_discount", price_discount)
	config.set_value("prestige", "auto_clicks_per_second", auto_clicks_per_second)
	var now = get_utc_unix_time()
	for i in range(achievements.size()):
		if "check" in achievements[i]:
			config.set_value("achievements", "ach_" + str(i), achievements[i].unlocked)
		elif "targets" in achievements[i]:
			config.set_value("achievements", "prog_" + str(i) + "_level", achievements[i].current_level)
			config.set_value("achievements", "prog_" + str(i) + "_unlocked", achievements[i].unlocked_levels)
	config.set_value("meta", "last_time", int(now))
	config.save("user://savegame.cfg")

func load_game():
	var config = ConfigFile.new()
	var err = config.load("user://savegame.cfg")
	if err == OK:
		points_per_second = 0
		for i in generators.size():
			var count = config.get_value("generators", "gen_" + str(i), 0)
			var gen = generators[i]
			gen.count = count
			generators[i] = gen
			points_per_second += gen.count * gen.gain
		points = config.get_value("player", "points", 0)
		points_per_click = config.get_value("player", "points_per_click", 1)
		prestige_points = config.get_value("prestige", "points", 0)
		prestige_multiplier = config.get_value("prestige", "multiplier", 1.0)
		click_bonus = config.get_value("prestige", "click_bonus", 0)
		idle_multiplier = config.get_value("prestige", "idle_multiplier", 1.0)
		price_discount = config.get_value("prestige", "price_discount", 0.0)
		auto_clicks_per_second = config.get_value("prestige", "auto_clicks_per_second", 0)
		for i in range(achievements.size()):
			if "check" in achievements[i]:
				achievements[i].unlocked = config.get_value("achievements", "ach_" + str(i), false)
			elif "targets" in achievements[i]:
				achievements[i].current_level = config.get_value("achievements", "prog_" + str(i) + "_level", 0)
				achievements[i].unlocked_levels = config.get_value("achievements", "prog_" + str(i) + "_unlocked", [])
				if achievements[i].unlocked_levels == null:
					achievements[i].unlocked_levels = []
		var now = get_utc_unix_time()
		var last_time = int(config.get_value("meta", "last_time", 0))
		var diff = now - last_time
		if diff < 0:
			diff = 0
		var idle_gain = diff * points_per_second * prestige_multiplier * idle_multiplier
		points += idle_gain
		if idle_gain > 0:
			offline_dialog.dialog_text = "💰 Vítej zpět!\nZískal jsi +" + str(int(idle_gain)) + " bodů."
			offline_dialog.popup_centered()
		print("last_time =", last_time)
		print("now =", now)
		print("Offline idle: ", diff, "s ×", points_per_second, "×", prestige_multiplier, "=", idle_gain, " bodů")
	else:
		print("Chyba při načítání savegame.cfg!")

func on_auto_click():
	points += auto_clicks_per_second * points_per_click * prestige_multiplier
	update_upgrade_button_texts()
	update_ui()

func _exit_tree():
	save_game()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
