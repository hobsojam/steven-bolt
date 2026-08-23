extends RefCounted

# Hand-authored MVP level. Pacing (start count 20, RunRules.START_CROWD_COUNT):
#   Row 1 @20  - introduces the mechanic; the "obvious" center lane hides a
#                small penalty, teaching players to read every lane.
#   Row 2 @40  - a big win sits directly beside a heavy loss, testing
#                precision steering rather than just sign-reading.
#   Row 3 @62  - values escalate and alternate sign every lane.
#   Row 4 @85  - a jackpot lane flanked by two harsh penalty lanes; the
#                deceptive trap is that the tempting *center* pick is both
#                the biggest reward and one miss-steer away from the worst
#                loss on the board.
#   Toll  @110 - threshold tuned so a mostly-good run clears it with room to
#                spare but a couple of bad picks along the way fails it.
#   Finish@140 - short victory stretch after the wall.


static func length() -> float:
	return 140.0


static func entries() -> Array[Dictionary]:
	return [
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
