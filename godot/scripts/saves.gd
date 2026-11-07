extends RefCounted

const VERSION := 1
const MAX_STAGE := 13

static func slot_path(mode: String) -> String:
	if mode == "Story":
		return "user://story.json"
	if mode == "Free Roam":
		return "user://free_roam.json"
	return ""

static func valid_position(value) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for n in value:
		if not (n is float or n is int) or not is_finite(float(n)) or absf(float(n)) > 950.0:
			return false
	return float(value[1]) >= -5.0

static func valid(data, mode: String) -> bool:
	if not data is Dictionary or data.get("version") != VERSION or data.get("mode") != mode:
		return false
	if not valid_position(data.get("position")):
		return false
	var hp = data.get("health")
	if not (hp is float or hp is int) or not is_finite(float(hp)) or hp <= 0 or hp > 100:
		return false
	var index = data.get("stage")
	if not (index is int or index is float) or index != floor(index) or index < 0 or index > MAX_STAGE:
		return false
	for key in ["crime_sequence", "crime_completed", "crime_failed", "crime_timer"]:
		if data.has(key):
			var n = data[key]
			if not (n is int or n is float) or not is_finite(float(n)) or n < 0 or n > 1000000:
				return false
	for key in ["crime_phase", "crime_type"]:
		if data.has(key) and not data[key] is String:
			return false
	for key in ["checkpoint", "crime_target", "escort"]:
		if data.has(key) and not valid_position(data[key]):
			return false
	if data.has("enemies"):
		if not data.enemies is Array or data.enemies.size() > 3:
			return false
		for enemy in data.enemies:
			if not enemy is Dictionary or not valid_position(enemy.get("position")):
				return false
			var enemy_hp = enemy.get("health")
			if not (enemy_hp is int or enemy_hp is float) or not is_finite(float(enemy_hp)) or enemy_hp <= 0 or enemy_hp > 200:
				return false
	return true

static func read(mode: String) -> Dictionary:
	var path := slot_path(mode)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	return data if valid(data, mode) else {}

static func write(mode: String, data: Dictionary) -> bool:
	var path := slot_path(mode)
	if path.is_empty() or not valid(data, mode):
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK
