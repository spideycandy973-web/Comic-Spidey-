extends RefCounted

# Crossings are on the native city's 44 metre road grid. All objectives
# take place on streets, so they remain reachable with the building collisions.
const STORY := [
	{"type":"travel", "title":"Investigate the disturbance", "dialogue":"Spider-Man: Sirens ahead. I should check that crossing.", "at":Vector3(0,0,-44)},
	{"type":"fight", "title":"Stop the attackers", "dialogue":"Spider-Man: They are stealing electrical parts. Time to stop them!", "at":Vector3(0,0,-44), "count":2},
	{"type":"travel", "title":"Reach the north crossing", "dialogue":"Spider-Man: That signal is heading north. Follow it!", "at":Vector3(0,0,-132)},
	{"type":"boss", "title":"Stop Doctor Octopus", "dialogue":"Doctor Octopus: My arms will make short work of you!", "at":Vector3(0,0,-132)},
	{"type":"travel", "title":"Find the power relay", "dialogue":"Spider-Man: Ock is feeding power through a nearby relay.", "at":Vector3(88,0,-132)},
	{"type":"interact", "title":"Disable the power relay", "dialogue":"Spider-Man: Shut down the relay before it overloads.", "at":Vector3(88,0,-132)},
	{"type":"travel", "title":"Find the stranded civilian", "dialogue":"Civilian: Help! I cannot get through the chaos!", "at":Vector3(176,0,-132)},
	{"type":"escort", "title":"Escort the civilian to safety", "dialogue":"Civilian: I will follow you. Please stay close!", "at":Vector3(176,0,-132), "destination":Vector3(176,0,-44)},
	{"type":"travel", "title":"Follow the getaway crew", "dialogue":"Spider-Man: The getaway crew has the stolen parts.", "at":Vector3(264,0,-44)},
	{"type":"fight", "title":"Stop the getaway crew", "dialogue":"Attacker: You will never reach the generator!", "at":Vector3(264,0,-44), "count":3},
	{"type":"travel", "title":"Reach the generator", "dialogue":"Spider-Man: One last signal. I have to stop that generator.", "at":Vector3(264,0,-132)},
	{"type":"boss", "title":"Confront Doctor Octopus", "dialogue":"Doctor Octopus: Too late, Spider-Man. The city is mine!", "at":Vector3(264,0,-132)},
	{"type":"interact", "title":"Stabilize the generator", "dialogue":"Spider-Man: Ock is down. Now stabilize the generator!", "at":Vector3(264,0,-132)},
	{"type":"complete", "title":"City secured", "dialogue":"Spider-Man: The city is safe. Time for another patrol!", "at":Vector3(264,0,-132)}
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
