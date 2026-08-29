extends RefCounted

# Maps a level entry's "kind" string to an encounter instance. This is
# the one place run_controller.gd learns about specific encounter types;
# see encounter.gd for the lifecycle a new type has to implement and the
# full list of steps to add one.

const EnemyWaveEncounter := preload("res://scripts/enemy_wave_encounter.gd")
const RivalCrowdEncounter := preload("res://scripts/rival_crowd_encounter.gd")
const HordeEncounter := preload("res://scripts/horde_encounter.gd")

const KINDS := ["enemy_wave", "rival_crowd", "horde"]


static func is_encounter(kind: String) -> bool:
	return KINDS.has(kind)


static func create(entry: Dictionary):
	match entry["kind"]:
		"enemy_wave":
			return EnemyWaveEncounter.new(entry)
		"rival_crowd":
			return RivalCrowdEncounter.new(entry)
		"horde":
			return HordeEncounter.new(entry)
	return null
