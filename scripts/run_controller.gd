extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")

var distance_traveled: float = 0.0

@onready var _crowd: Node3D = $CrowdController


func _process(delta: float) -> void:
	distance_traveled += RunRules.RUN_SPEED * delta
	_crowd.position.z = -distance_traveled
