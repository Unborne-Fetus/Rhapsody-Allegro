extends RefCounted
## Single roster source for campaign bounds and save migration.
static func roster() -> Array:
	var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/bosses.json"))
	return value if value is Array else []
static func last_index() -> int:
	return maxi(0,roster().size()-1)
