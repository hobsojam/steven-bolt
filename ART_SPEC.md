# Steven Bolt — Art Spec

## Game context

- Godot 4.7, true 3D (`Node3D`), GL Compatibility renderer, portrait viewport
  **480×854px**, `stretch/mode = canvas_items`.
- Forced-perspective 3D crowd-runner (Crowd City / Count Masters lineage):
  third-person chase camera behind the player, road receding into the
  distance. **5 fixed lanes**, centers at world X = -3.2, -1.6, 0, 1.6, 3.2
  (1.6m spacing) — see `scripts/run_rules.gd`.
- The player is a crowd of many identical low-poly units rendered through a
  single `MultiMeshInstance3D` (`scripts/crowd_visual.gd`), up to 150
  instances on screen at once. **All instances share one material/texture**
  — there's no per-unit texture variation without a shader change. Flag it
  if you want that; it's a small addition on my end, not something the art
  alone can do.
- **Update: items 1-6 below are done.** The first art pass (this spec,
  originally) replaced the crowd/gates/toll-wall/road/sky/UI-theme
  placeholders with real `.glb` models, a road texture, a procedural sky,
  and a `Theme` resource — all live in the project now. Two mechanics
  (auto-fire combat, the pickup-trail lanes) were built *after* that pass
  and are still primitive placeholders: **items 7-9 are the new ask.**
- Enemies, bullets, and pickup markers are each a plain individual
  `MeshInstance3D` (`scripts/enemy_wave_visual.gd`, `scripts/pickup.gd`) —
  **not** MultiMesh like the crowd. Per-instance material/texture variety is
  totally fine for these if you want it; the MultiMesh constraint above only
  applies to the crowd unit.
- Full mechanics reference: `GAME_SPEC.md`.

## Art direction

- **Style: bright, chunky, toy-like hypercasual mobile.** Think Crowd City /
  Count Masters / Join Clash — simple rounded low-poly shapes, saturated
  color, bold readable silhouettes. Units are small on screen and there can
  be 150 of them at once, so favor clear shape over fine detail or texture
  noise.
- **Mood: cheerful and energetic, not realistic.** A sunny, colorful world
  fits the genre — and fits the fact that this project has zero
  monetization pressure behind it (see `AGENTS.md`); it's meant to be fun to
  look at, not to bait engagement.
- **Color-coding drives readability at speed.** Green = good/gain, red =
  bad/danger, consistently across gates, the toll wall, and any UI danger
  states.

### Established palette (from the completed first pass — match these for 7-9)

| Element | Color |
|---|---|
| Crowd unit | `#F28C26` (orange) |
| Gate: positive | `#42D67B` main / `#BFF5D1` number panel |
| Gate: negative | `#EB4D5C` main / `#681D2B` number panel |
| Toll wall / danger | `#C93643` ("Barrier red" — also used for the current enemy placeholder) |
| Bullet placeholder | `#FFF59D` (pale glowing yellow) |

All of the above are authored as conventional sRGB hex and converted with
`Color.srgb_to_linear()` before assignment to `StandardMaterial3D.albedo_color`
(it's a linear-space property) — see `tools/generate_art_assets.gd`'s
`_material()` helper and `scripts/enemy_wave_visual.gd`. Do the same for any
new hex colors you pick.

## Asset list

**Items 1-6 are done** (real assets already in the project) — kept below for
reference/context, not as an active ask. **Items 7-9 are the new ask.**

### 1. Crowd unit character model — done
- Delivered as `assets/models/crowd_unit.glb`, ~1m tall, origin at ground
  level (feet at local `y=0`) — that's why `scripts/crowd_visual.gd` no
  longer needs a manual grounding offset; scaling happens around that same
  origin so it stays grounded at every size.
- A simple, appealing "blob person" — chunky rounded body, an oversized head
  is fine and reads better at small scale/distance. No fingers or facial
  detail needed. A single static pose is enough (arms-forward running pose
  or a simple idle both work).
- The game **shrinks this model uniformly at runtime** as the crowd count
  grows (down to 50% scale — see `RunRules.crowd_unit_scale()`). Author it
  once at the full-size bounding box above; you don't need multiple size
  variants.
- **Poly budget: ≤800 triangles.** Up to 150 instances render simultaneously
  via MultiMesh, targeting a mobile GL Compatibility renderer — stay
  conservative.
- **Texture: one material shared by every instance** (see the MultiMesh
  note in Game Context above). A flat-shaded or simple two-tone material is
  enough; a small texture (≤512×512) is fine if you want more visual
  interest, but isn't required.
- Orientation: facing -Z (the direction of travel), origin at ground level
  (feet at local y=0) so it drops in without a position offset.
- Optional stretch: a run/bob animation needs a vertex-shader-driven
  approach — `MultiMesh` can't skeletally animate individual instances.
  Flag it and I'll wire up the shader side; a skeletal/bone animation export
  won't be usable as-is, don't spend budget on one without checking first.

### 2. Gate sign (spans one lane, shows a math op) — done
- Currently just floating `Label3D` text (`scripts/gate_row.gd`). Replace
  with an actual archway/banner structure the crowd visibly runs through,
  with the `+N`/`−N` value displayed on it.
- Footprint: fits within **one lane's ~1.6m width**, tall enough to read
  from the chase camera (roughly 1.5–2m). Positioned so the crowd runs
  *through* it, not into it.
- Two visual states by sign: **positive** (green, open/inviting) and
  **negative** (red, hazard-striped or cracked/warning). The number itself
  stays dynamic text that I'll keep wiring in code — leave a clear flat
  readable area on the sign for it.
- Poly budget: **≤300 triangles per gate** — there are up to 5 visible in a
  row at once.

### 3. Toll wall (obstacle barrier) — done
- Currently a flat translucent red `BoxMesh` (`scripts/toll_wall.gd`).
  Replace with a barrier that reads as a genuine obstacle: **~8m wide × 3m
  tall × 0.2–0.5m thick** (matches `RunRules.CROWD_MAX_WIDTH + 2.0`).
- A gate/portcullis, stacked crates, a stone barricade — whatever sells
  "you need enough crowd to break through this." Danger-red palette,
  consistent with negative gates.
- The threshold number is dynamic text I'll keep wiring separately — leave
  a clear panel/banner area on the wall for it.
- Poly budget: **≤500 triangles.**

### 4. Track / road surface — done
- Currently a flat gray `PlaneMesh`, **8m wide × 180m long**
  (`scenes/main.tscn`), no texture. A tileable road texture (lane stripes,
  surface detail) would sell forward motion far better than a flat color.
- Deliver as a **tileable texture** (512×512 or 1024×1024, seamless along
  the long axis) — the plane geometry stays as-is, this is a material swap
  only, not a new mesh.
- Optional stretch: simple low-poly roadside props (curbs, occasional
  scenery) to sell speed and depth. If you go this route, keep individual
  prop poly counts low (≤200 tris each) since several may be visible at
  once, receding toward the horizon.

### 5. Sky / environment backdrop — done
- Currently nothing — no skybox, no environment, just Godot's default clear
  color. The scene has no sense of place right now.
- **Cheapest option, no art file needed:** give me two colors (sky/horizon)
  and I'll wire up a Godot `ProceduralSkyMaterial` via `WorldEnvironment` —
  zero-cost, nothing to deliver.
- If you want more: a soft gradient or painted skybox (equirectangular
  panorama, or a Godot `PanoramaSkyMaterial`) — keep it soft/out-of-focus so
  it doesn't compete with foreground readability.

### 6. UI / HUD theme — done
- Currently plain default Godot `Label`s, no theme
  (`scripts/game_hud.gd`, `scenes/main.tscn`). Could use a real look: a
  distinct font, a colored/rounded panel behind the crowd-count readout,
  and a treatment for the start-screen title and the game-over/level-
  complete banners.
- Deliver as a Godot `Theme` resource (`.tres`) if you're comfortable
  authoring one directly, or just hand me a font file plus color/style
  notes and I'll build the `Theme` resource myself.

### 7. Enemy model — new
- Currently a plain red `CapsuleMesh` (`scripts/enemy_wave_visual.gd`).
  Enemies are stationary level content the crowd approaches and shoots down
  — same as gates, they're spawned and visible from a distance for the
  whole run, not a surprise pop-in (see `run_controller.gd`'s
  `_spawn_level_visuals()`).
- Bounding box target: **~0.6m diameter × 1.4m tall** (matches the current
  placeholder capsule's radius/height).
- Style: same toy/chibi language as the crowd unit, but reads as hostile —
  darker, spikier silhouette, danger-red palette (`#C93643`, see the
  established palette above). No animation needed; enemies don't move, only
  the crowd's bullets travel toward them.
- Origin at ground level (feet at local `y=0`), same convention as the crowd
  unit — I'll reposition `enemy_wave_visual.gd` to match once you hand this
  over (it currently assumes a center-origin primitive).
- **Poly budget: ≤500 triangles.** Only 1-2 enemies are ever visible per
  wave right now, so there's headroom versus the crowd unit's 800 budget.

### 8. Bullet model — new
- Currently a small emissive yellow `SphereMesh` (`scripts/enemy_wave_visual.gd`).
- A simple glowing projectile/energy bolt — the pale yellow placeholder
  color (`#FFF59D`) reads fine as "friendly fire," but pick whatever sells
  "the crowd is shooting" at a glance.
- Bounding box: **~0.2–0.3m** — small and fast-moving, not a focal object.
  Centered origin is fine (no ground-level constraint, it flies at chest
  height).
- **Poly budget: ≤100 triangles.** Keep it very cheap; several can exist on
  screen at once.

### 9. Pickup marker — new
- Currently just floating `Label3D` text, no model at all
  (`scripts/pickup.gd`). A small collectible marker (coin, flag, orb —
  whatever reads as "run through this to collect it") for the pickup-trail
  lanes, which repeat one marker every few meters along a single lane for a
  stretch of track.
- Bounding box: fits within **one lane's ~1.6m width**, modest height
  (~0.5–1m) — much smaller than a full gate archway, since these repeat
  frequently rather than appearing once.
- The `+N`/`−N` value stays dynamic text I'll keep wiring in code — leave a
  clear flat readable area near the marker for it.
- **Poly budget: ≤150 triangles** — several can be visible in a row along a
  trail at once.

## Delivery format

- **Models: glTF 2.0, `.glb`** (single file, textures embedded) — Godot's
  built-in importer, no addons needed.
- **Textures:** PNG, power-of-two dimensions, ≤512×512 unless a specific
  asset calls for more (the road texture may go to 1024×1024 if it needs
  more surface detail).
- Name files descriptively (e.g. `enemy.glb`, `bullet.glb`,
  `pickup_marker.glb`) — exact names don't matter, just tell me what's what
  on handoff. Drop them anywhere in the repo and I'll do all the Godot-side
  integration: import settings, swapping out the primitive placeholders,
  wiring materials/instancing.

## Out of scope for this pass

- No skins/unlockable crowd variants — no meta-progression in this project,
  and no monetization of any kind is planned (see `AGENTS.md`).
- No `×N`/`÷N` gate visuals — that gate type is deferred to v2+ per
  `GAME_SPEC.md`.
- No rival-crowd-battle visuals — also deferred to v2+.
- No cutscene art. The title screen is just the existing HUD start overlay.
