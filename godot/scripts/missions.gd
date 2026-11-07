extends RefCounted

# Crossings are on the native city's 44 metre road grid. All objectives
# take place on streets, so they remain reachable with the building collisions.
const STORY := [
	{"type":"travel", "title":"Investigate the disturbance", "at":Vector3(0,0,-44)},
	{"type":"fight", "title":"Stop the attackers", "at":Vector3(0,0,-44), "count":2},
	{"type":"travel", "title":"Reach the north crossing", "at":Vector3(0,0,-132)},
	{"type":"boss", "title":"Stop Doctor Octopus", "at":Vector3(0,0,-132)},
	{"type":"travel", "title":"Find the power relay", "at":Vector3(88,0,-132)},
	{"type":"interact", "title":"Disable the power relay", "at":Vector3(88,0,-132)},
	{"type":"travel", "title":"Find the stranded civilian", "at":Vector3(176,0,-132)},
	{"type":"escort", "title":"Escort the civilian to safety", "at":Vector3(176,0,-132), "destination":Vector3(176,0,-44)},
	{"type":"travel", "title":"Follow the getaway crew", "at":Vector3(264,0,-44)},
	{"type":"fight", "title":"Stop the getaway crew", "at":Vector3(264,0,-44), "count":3},
	{"type":"travel", "title":"Reach the generator", "at":Vector3(264,0,-132)},
	{"type":"boss", "title":"Confront Doctor Octopus", "at":Vector3(264,0,-132)},
	{"type":"interact", "title":"Stabilize the generator", "at":Vector3(264,0,-132)},
	{"type":"complete", "title":"City secured", "at":Vector3(264,0,-132)}
]
const CRIMES := ["assault", "rescue", "sabotage"]

static func story_stage(index: int) -> Dictionary:
	return STORY[clampi(index, 0, STORY.size() - 1)]

static func near(a: Vector3, b: Vector3, radius: float) -> bool:
	return absf(a.y - b.y) < 3.0 and Vector2(a.x - b.x, a.z - b.z).length() < radius

static func crime_location(at: Vector3, sequence: int) -> Vector3:
	# Keep all encounter positions inside the finite physics floor.
	var x := clampf(roundf(at.x / 44.0) * 44.0, -880.0, 880.0)
	var z := clampf(roundf(at.z / 44.0) * 44.0 + (-44.0 if sequence % 2 == 0 else 44.0), -880.0, 880.0)
	return Vector3(x, 0, z)
