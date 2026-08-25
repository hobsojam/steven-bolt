extends Node3D

enum RunState { START, RUNNING, GAME_OVER, FINISHED }

const RunRules := preload("res://scripts/run_rules.gd")
const LevelOneDefinition := preload("res://scripts/level_one_definition.gd")
const GateRowScript := preload("res://scripts/gate_row.gd")
const TollWallScript := preload("res://scripts/toll_wall.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const CombatRules := preload("res://scripts/combat_rules.gd")
const EnemyWaveRuntimeScript := preload("res://scripts/enemy_wave_runtime.gd")
const EnemyWaveVisualScript := preload("res://scripts/enemy_wave_visual.gd")
const RivalCrowdRuntimeScript := preload("res://scripts/rival_crowd_runtime.gd")
const RivalCrowdVisualScript := preload("res://scripts/rival_crowd_visual.gd")
const CrowdUnitModel := preload("res://assets/models/crowd_unit.glb")
const EnemyModel := preload("res://assets/models/enemy.glb")

# How far ahead of a horde's engage distance shooting can start (a horde
# would otherwise sit in firing range for the crowd's entire preceding run,
# trivializing even a large one - see run_controller.gd's horde design doc).
const HORDE_SHOOT_RANGE := 20.0

var distance_traveled: float = 0.0
var _elapsed_time: float = 0.0
var _state: int = RunState.START
var _level_entries: Array[Dictionary] = []
var _next_entry_index: int = 0
var _active_wave = null
var _active_wave_visual: Node3D = null
var _active_rival = null
var _active_rival_visual: Node3D = null
var _active_rival_engage_distance: float = 0.0
var _active_horde = null
var _active_horde_visual: Node3D = null
var _active_horde_engage_distance: float = 0.0

@onready var _crowd = $CrowdController


func _ready() -> void:
	_level_entries = LevelOneDefinition.entries()
	_spawn_level_visuals()


func _process(delta: float) -> void:
	if _state == RunState.START:
		if Input.is_action_just_pressed("ui_accept"):
			_state = RunState.RUNNING
		return
	if _state != RunState.RUNNING:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	_elapsed_time += delta
	distance_traveled += RunRules.current_speed(_elapsed_time) * delta
	_crowd.position.z = -distance_traveled
	_resolve_pending_entries()
	if _active_wave:
		_update_combat(delta)
	if _active_rival:
		_update_rival_battle(delta)
	if _active_horde:
		_update_horde(delta)
	if _state == RunState.RUNNING and distance_traveled >= LevelOneDefinition.length():
		_state = RunState.FINISHED


func is_start() -> bool:
	return _state == RunState.START


func is_game_over() -> bool:
	return _state == RunState.GAME_OVER


func is_finished() -> bool:
	return _state == RunState.FINISHED


func _resolve_pending_entries() -> void:
	while (
		_next_entry_index < _level_entries.size()
		and distance_traveled >= _level_entries[_next_entry_index]["distance"]
	):
		_resolve_entry(_level_entries[_next_entry_index])
		_next_entry_index += 1
		if _state != RunState.RUNNING:
			return


func _resolve_entry(entry: Dictionary) -> void:
	match entry["kind"]:
		"gate_row":
			var lane_data: Dictionary = entry["lanes"][_crowd.current_lane]
			_crowd.apply_gate(lane_data["op"], lane_data["value"])
			if _crowd.crowd_count <= 0:
				_state = RunState.GAME_OVER
		"toll_wall":
			if not _crowd.apply_toll(entry["threshold"]):
				_state = RunState.GAME_OVER
		"pickup":
			if _crowd.current_lane == entry["lane"]:
				_crowd.apply_gate(entry["op"], entry["value"])


func _update_combat(delta: float) -> void:
	var damage: int = CombatRules.shot_damage(_crowd.crowd_count)
	_active_wave.try_fire(_crowd.current_lane, distance_traveled, damage, delta)
	_active_wave.advance_bullets(delta)
	_active_wave.resolve_hits()
	var breach_cost: int = _active_wave.resolve_breaches(distance_traveled)
	if breach_cost > 0:
		_crowd.apply_breach(breach_cost)
		if _crowd.crowd_count <= 0:
			_state = RunState.GAME_OVER
	if _active_wave.is_cleared():
		_active_wave_visual.queue_free()
		_active_wave = null
		_active_wave_visual = null


func _update_rival_battle(delta: float) -> void:
	if distance_traveled < _active_rival_engage_distance:
		return
	# Motion never stops elsewhere in this game, so once engaged the rival
	# visual tracks the crowd's own Z every frame instead of staying at its
	# spawned position - "crowds mashed together fighting" rather than the
	# crowd visibly running past a stationary rival mid-battle.
	_active_rival_visual.position.z = _crowd.position.z
	var loss: int = _active_rival.tick(delta, _crowd.crowd_count)
	if loss > 0:
		_crowd.apply_breach(loss)
		if _crowd.crowd_count <= 0:
			_state = RunState.GAME_OVER
	if _active_rival.is_defeated():
		_active_rival_visual.queue_free()
		_active_rival = null
		_active_rival_visual = null


func _update_horde(delta: float) -> void:
	var distance_to_horde: float = _active_horde_engage_distance - distance_traveled
	if distance_to_horde > HORDE_SHOOT_RANGE:
		# Not yet in range: the horde sits at its spawned position, visible
		# from a distance (like every other pre-spawned encounter) but not
		# yet interactable.
		return
	if distance_traveled < _active_horde_engage_distance:
		# Approaching but not yet in contact: shoot it down. A clean kill
		# here costs the player nothing, same reward as clearing an
		# enemy_wave before it breaches.
		var damage: int = CombatRules.shot_damage(_crowd.crowd_count)
		_active_horde.apply_shot_damage(delta, damage, distance_traveled)
		_active_horde.advance_bullets(delta, _active_horde_engage_distance)
		if _active_horde.is_defeated():
			_active_horde_visual.queue_free()
			_active_horde = null
			_active_horde_visual = null
		return
	# Contact reached with survivors left: identical to _update_rival_battle's
	# mutual attrition, since apply_shot_damage() and tick() share the same
	# rival_count and tick() doesn't care how that count got where it is.
	# Any bullet still mid-flight from the instant contact was reached loses
	# its narrative meaning (the horde it was headed for is right there now)
	# so it's dropped rather than animated the rest of the way in.
	_active_horde.bullets.clear()
	_active_horde_visual.position.z = _crowd.position.z
	var loss: int = _active_horde.tick(delta, _crowd.crowd_count)
	if loss > 0:
		_crowd.apply_breach(loss)
		if _crowd.crowd_count <= 0:
			_state = RunState.GAME_OVER
	if _active_horde.is_defeated():
		_active_horde_visual.queue_free()
		_active_horde = null
		_active_horde_visual = null


func _spawn_level_visuals() -> void:
	for entry in _level_entries:
		var visual
		match entry["kind"]:
			"gate_row":
				visual = GateRowScript.new()
			"toll_wall":
				visual = TollWallScript.new()
			"pickup":
				visual = PickupScript.new()
			"enemy_wave":
				# Unlike gate_row/toll_wall/pickup (resolved once, instantly,
				# when crossed), an enemy wave exists and is simulated from
				# level start - same as gates being visible from a distance
				# via the chase camera's lookahead, rather than popping in
				# right before the crowd reaches it. _update_combat() runs
				# every frame in _process() while _active_wave is set.
				_active_wave = EnemyWaveRuntimeScript.new(entry["enemies"])
				_active_wave_visual = EnemyWaveVisualScript.new(_active_wave)
				add_child(_active_wave_visual)
			"rival_crowd":
				_active_rival = RivalCrowdRuntimeScript.new(entry["count"])
				_active_rival_visual = RivalCrowdVisualScript.new(
					_active_rival,
					CrowdUnitModel,
					Color("3a6ea5").srgb_to_linear(),
					true
				)
				_active_rival_engage_distance = entry["distance"]
				_active_rival_visual.position.z = -entry["distance"]
				add_child(_active_rival_visual)
			"horde":
				_active_horde = RivalCrowdRuntimeScript.new(entry["count"])
				_active_horde_visual = RivalCrowdVisualScript.new(
					_active_horde,
					EnemyModel,
					null,
					true
				)
				_active_horde_engage_distance = entry["distance"]
				_active_horde_visual.position.z = -entry["distance"]
				add_child(_active_horde_visual)
		if visual:
			add_child(visual)
			visual.setup(entry)
