extends RefCounted

# Hand-authored MVP level. Pacing (start count 20, RunRules.START_CROWD_COUNT):
#   Row 1 @20     - introduces the mechanic; the "obvious" center lane hides
#                   a small penalty, teaching players to read every lane.
#   Enemies @26-36 - two enemies span lanes 1-2. Breach cost applies per
#                   un-killed enemy regardless of your own lane, so sitting
#                   in an empty lane (0, 3, 4) doesn't dodge anything - it
#                   guarantees paying for both. Killing the enemy in your
#                   current lane is free; steering from lane 1 to lane 2
#                   during the encounter can clear both.
#   Row 2 @40     - a big win sits directly beside a heavy loss, testing
#                   precision steering rather than just sign-reading.
#   Trail @44-58  - lane 3 has a run of small +4 pickups; committing to that
#                   lane for the whole stretch is worth more than any single
#                   gate, but you only collect the ones you're actually in
#                   the lane for.
#   Row 3 @62     - values escalate and alternate sign every lane.
#   Row 4 @85     - a jackpot lane flanked by two harsh penalty lanes; the
#                   deceptive trap is that the tempting *center* pick is both
#                   the biggest reward and one miss-steer away from the worst
#                   loss on the board.
#   Toll  @110    - threshold tuned so a mostly-good run clears it with room
#                   to spare but a couple of bad picks along the way fails it.
#   Finish@140    - short victory stretch after the wall.


static func length() -> float:
	return 140.0


static func expand_pickup_trail(entry: Dictionary) -> Array[Dictionary]:
	var pickups: Array[Dictionary] = []
	var distance: float = entry["start_distance"]
	while distance <= entry["end_distance"] + 0.001:
		pickups.append(
			{
				"distance": distance,
				"kind": "pickup",
				"lane": entry["lane"],
				"op": entry["op"],
				"value": entry["value"],
			}
		)
		distance += entry["spacing"]
	return pickups


static func entries() -> Array[Dictionary]:
	var raw: Array[Dictionary] = [
		{
			"distance": 20.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "+", "value": 10},
				{"op": "+", "value": 5},
				{"op": "-", "value": 5},
				{"op": "+", "value": 8},
				{"op": "+", "value": 3},
			],
		},
		{
			"distance": 26.0,
			"kind": "enemy_wave",
			"enemies": [
				{"lane": 1, "distance": 32.0, "hp": 2},
				{"lane": 2, "distance": 36.0, "hp": 2},
			],
		},
		{
			"distance": 40.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "+", "value": 20},
				{"op": "-", "value": 30},
				{"op": "+", "value": 50},
				{"op": "-", "value": 10},
				{"op": "+", "value": 15},
			],
		},
		{
			"distance": 44.0,
			"kind": "pickup_trail",
			"lane": 3,
			"start_distance": 44.0,
			"end_distance": 58.0,
			"spacing": 3.5,
			"op": "+",
			"value": 4,
		},
		{
			"distance": 62.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "-", "value": 40},
				{"op": "+", "value": 80},
				{"op": "-", "value": 20},
				{"op": "+", "value": 60},
				{"op": "-", "value": 25},
			],
		},
		{
			"distance": 85.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "+", "value": 30},
				{"op": "-", "value": 100},
				{"op": "+", "value": 150},
				{"op": "-", "value": 60},
				{"op": "+", "value": 40},
			],
		},
		{
			"distance": 110.0,
			"kind": "toll_wall",
			"threshold": 120,
		},
	]

	var expanded: Array[Dictionary] = []
	for entry in raw:
		if entry["kind"] == "pickup_trail":
			expanded.append_array(expand_pickup_trail(entry))
		else:
			expanded.append(entry)
	expanded.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return expanded
