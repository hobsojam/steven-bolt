extends RefCounted

# Environment content is plain data, same principle as
# level_one_definition.gd: an ordered, contiguous list of distance-ranged
# zones tiling the whole level, each describing the sky/mood for that
# stretch of track. scripts/environment_controller.gd is the thin layer
# that turns this into an actual sky/prop change.
#
# Colors are authored as conventional sRGB hex, same convention as
# tools/generate_art_assets.gd's _material() helper - call
# Color.srgb_to_linear() before assigning to a linear-space material
# property (ProceduralSkyMaterial's sky/horizon colors included).


static func zones() -> Array[Dictionary]:
	return [
		{
			"start_distance": 0.0,
			"end_distance": 40.0,
			"sky_top": Color("1b89e5"),
			"sky_horizon": Color("b8ecff"),
			"ambient_energy": 0.48,
			"prop_type": "tree",
			"prop_spacing": 8.0,
		},
		{
			"start_distance": 40.0,
			"end_distance": 85.0,
			"sky_top": Color("1670d6"),
			"sky_horizon": Color("7fd4ff"),
			"ambient_energy": 0.52,
			"prop_type": "tree",
			"prop_spacing": 5.0,
		},
		{
			"start_distance": 85.0,
			"end_distance": 120.0,
			"sky_top": Color("2b3a67"),
			"sky_horizon": Color("6b7fa3"),
			"ambient_energy": 0.30,
			"prop_type": "rock",
			"prop_spacing": 6.0,
		},
		{
			"start_distance": 120.0,
			"end_distance": 150.0,
			"sky_top": Color("ff9f45"),
			"sky_horizon": Color("ffe29a"),
			"ambient_energy": 0.55,
			"prop_type": "banner",
			"prop_spacing": 10.0,
		},
	]


static func zone_for_distance(distance: float, zones_list: Array[Dictionary]) -> Dictionary:
	for zone in zones_list:
		if distance < zone["end_distance"]:
			return zone
	return zones_list[zones_list.size() - 1]
