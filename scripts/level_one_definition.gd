extends RefCounted

# Placeholder gate rows for exercising the crowd-math loop end to end.
# The real hand-authored MVP level (escalating thresholds, deceptive gate
# rows, a toll wall, speed ramp) lands in a later pass.


static func entries() -> Array[Dictionary]:
	return [
		{
			"distance": 20.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "-", "value": 5},
				{"op": "+", "value": 10},
				{"op": "+", "value": 30},
				{"op": "+", "value": 8},
				{"op": "-", "value": 15},
			],
		},
		{
			"distance": 45.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "+", "value": 5},
				{"op": "-", "value": 40},
				{"op": "+", "value": 60},
				{"op": "-", "value": 10},
				{"op": "+", "value": 12},
			],
		},
		{
			"distance": 70.0,
			"kind": "gate_row",
			"lanes": [
				{"op": "-", "value": 20},
				{"op": "+", "value": 25},
				{"op": "-", "value": 200},
				{"op": "+", "value": 90},
				{"op": "-", "value": 5},
			],
		},
		{
			"distance": 90.0,
			"kind": "toll_wall",
			"threshold": 60,
		},
	]
