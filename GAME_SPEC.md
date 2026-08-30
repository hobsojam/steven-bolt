# Steven Bolt — Crowd Runner Game Spec

Design intent and a description of the current build. The active backlog
lives in **GitHub Issues**, not here — this document describes how the
game is meant to work and what is deliberately not built yet, not a task
list.

## Concept

A forward-auto-running "crowd" game in the Crowd City / Count Masters /
Join Clash lineage. The player steers a growing/shrinking mob of
followers that runs continuously down a track. The only input is steering
left/right across a set of lanes. Skill comes from reading gate rows,
managing crowd size against numeric obstacles, and clearing the combat
encounters without bleeding too much crowd.

This is a **separate project from sand-walker** — the core loop, camera,
and input model are all different. See "Relationship to sand-walker".

## What's built

The playable game today (`scenes/main.tscn`, one hand-authored level):

- True 3D (`Node3D`), Godot 4.7, GL Compatibility renderer, 480×854
  portrait viewport.
- Auto-run forward; run speed ramps from `RUN_SPEED` to `MAX_RUN_SPEED`
  over the run. 5 fixed lanes at 1.6 m spacing.
- Steering by `A`/`D`, arrow keys, mouse drag, or touch swipe. `Enter`
  starts the run and restarts after it ends.
- Run states: `START` → `RUNNING` → `GAME_OVER` or `FINISHED`.
- `+N` / `−N` gate rows, one value per lane; crowd count clamps at 0.
- Toll wall: passable only if `crowd_count >= threshold`, and consumes
  `threshold` units on the way through.
- Pickup trails: a run of `+N` markers down one lane, collected only
  while the crowd is in that lane.
- Enemy waves: stationary enemies with HP that the crowd auto-fires on as
  it approaches. Volley size scales with crowd count. An enemy still
  alive when the crowd reaches its position charges a fixed breach cost.
- Horde: a full-track enemy mass with two phases — a ranged shoot-down as
  the crowd approaches (a clean kill here is free), then, for whatever
  survives, mutual attrition on contact that costs the crowd the horde's
  remaining count.
- Fail state: `crowd_count` reaches 0 (gate underflow, enemy breach,
  horde contact, or a failed toll wall).
- Real low-poly `.glb` art for every element (crowd unit, enemy, gates,
  toll wall, bullet, pickup marker), a road texture, a procedural sky
  with four per-distance "mood" zones, an HUD theme, procedurally
  synthesized event SFX, and a combat/gate juice pass (spark bursts,
  muzzle flashes, tracer bullets, gate punch, floating numbers, camera
  punch/shake, a blob contact shadow). Placeholder primitive roadside
  props still stand in for real scenery — see `ART_SPEC.md` item 10.

## Systems detail

### Crowd representation
- Player state is a single integer: `crowd_count`.
- Rendered units are capped (`RunRules.MAX_RENDERED_UNITS`, currently 150)
  and drawn through one `MultiMeshInstance3D`; the HUD always shows the
  true integer count.
- Crowd footprint grows front-to-back from a roughly square base, only
  widening toward the track edges once depth would exceed the cap, and
  individual units shrink as the count climbs so a large crowd stays
  on-screen.

### Lanes
- 5 fixed lane slots. The crowd's lane is snapped on input (a gate can
  never resolve against a lane the crowd hasn't visibly reached); only a
  small within-lane "kick" is animated for feel.

### Gates
- Rows of 5, one value per lane. Types: `+N`, `−N`.
- Gate values are hand-tuned per row against the crowd size expected at
  that point in the level, so choices stay meaningful.
- Design intent, not built: `×N` / `÷N` (multiply is the
  highest-value/highest-risk since it compounds).

### Obstacles
- **Toll wall:** passable if `crowd_count >= threshold`; consumes
  `threshold` units. Failing it ends the run.
- Design intent, not built: a **checkpoint wall** that gates on the same
  threshold but consumes nothing — a pure test of prior gate choices.

### Enemy waves and shooting
- An enemy wave is a set of stationary enemies, each with a lane,
  distance, and HP, spawned and simulated from the start of the run (like
  gates, visible from a distance — not a pop-in).
- The crowd auto-fires at the nearest live enemy in its lane on a fixed
  cooldown. Volley size scales with crowd count up to a cap. Bullets
  travel and resolve against whichever enemy is nearest in their lane
  when they land.
- An enemy still alive when the crowd crosses its distance breaches for a
  fixed cost per head, regardless of the crowd's own lane. Clearing the
  wave first costs nothing.

### Horde and mass attrition
- The horde is a large enemy crowd spanning the whole track — no lane
  dodges it.
- **Ranged phase:** from a set distance ahead of the engage point up to
  contact, auto-fire reduces the horde one-sidedly (same fire cadence as
  a wave). A horde shot down before contact costs nothing.
- **Contact phase:** any survivors resolve by attrition — both sides lose
  units at a fixed rate per tick until one hits zero, converging on the
  same result an instant 1-for-1 subtraction would give
  (`survivors = |crowd − horde|`), spread over time for pacing.
- The attrition system (`rival_crowd_runtime.gd` / `rival_crowd_rules.gd`)
  is shared with a standalone `rival_crowd` encounter kind. That kind is
  wired end to end but no level entry uses it yet — a rival-crowd clash
  as its own level beat is design intent, not built.

### Level structure
- Level content is plain data (`scripts/level_one_definition.gd`): an
  ordered list of gate-row / toll-wall / pickup / enemy-wave / horde
  entries keyed by distance, plus a finish distance. Tuning or extending
  the level means editing this file, not the controllers.
- Multi-frame entries (enemy waves, hordes, rival crowds) are
  "encounters" behind a small lifecycle (`scripts/encounter.gd`); instant
  entries (gates, toll, pickups) are resolved directly. See `AGENTS.md`
  for the architecture notes.
- Difficulty ramps via larger thresholds, more deceptive gate rows, and
  rising run speed. Design intent, not built: a short multi-level
  progression (tracked in Issues).

### Camera / perspective
- Third-person chase camera, low and close with a tight FOV, so the crowd
  fills the lower frame and encounters tower ahead — the forced-
  perspective "road into the distance" signature of the genre.
- Reacts to events: a transient FOV punch on gate/toll pass, positional
  shake on a breach or a failed toll. Suppressed outside the `RUNNING`
  state.

### Controls
- Single-axis horizontal steering: `A`/`D` + arrow keys, mouse drag, or
  touch swipe. Crossing a pixel threshold advances one lane; a large drag
  advances several, keeping the remainder. No jump, no attack button, no
  manual shoot.

### Feedback
- `game_hud.gd` shows the crowd count, a lane indicator, and transient
  gate/pickup/combat feedback, plus start and end-of-run overlays.
- `feedback_audio.gd` synthesizes a short distinct tone per event at
  startup — no audio assets.
- `vfx.gd` and the encounter visuals provide the combat/gate juice:
  spark bursts on kills, staggered death pops, muzzle flashes across the
  crowd's front edge, stretched tracer bullets, a gate scale-punch with a
  floating `+N` / `−N`, and a "shred line" along a horde under fire.

## Not yet built

Design directions that are described above but not implemented. Anything
actionable and scheduled is a **GitHub Issue**; the rest is just
direction:

- `×N` / `÷N` gates; a non-consuming checkpoint wall.
- A rival-crowd clash as its own level beat (the system exists; no level
  uses it).
- Multiple levels + progression; an end-of-level celebration; route and
  balance simulation tests (these have Issues).
- Large-number formatting (`12.4K`, `3.1M`) once counts get big enough to
  need it.
- Branching track sections.
- Export presets / packaged builds (see `AGENTS.md`).

## Out of scope

- **No monetization of any kind**, ever — no ads, IAP, or currency hooks,
  not even inert scaffolding (see `AGENTS.md`).
- No skins / unlockable crowd variants, no meta-progression currency —
  there's nothing to spend it on and nothing to sell.

## Relationship to sand-walker

| | sand-walker | steven-bolt (this spec) |
|---|---|---|
| Camera | Top-down, fixed player position | Third-person chase, forced-perspective road |
| Movement | Player fixed near bottom, world scrolls down | Player auto-runs forward continuously |
| Player power | Bullets/damage vs. enemy HP | Crowd count vs. numeric thresholds; plus auto-fire vs. enemy HP |
| Input | Lane-switch (3 lanes) | Lane-switch (5 lanes), same gesture family |
| Combat | Direct shooting, enemies have HP/hit-stages | Crowd auto-fire vs. waves, plus mass-vs-mass attrition vs. hordes |
| Engine setup | Godot 4.7, `Node2D`, 480×854 portrait | Godot 4.7, `Node3D`, 480×854 portrait |

They share genre-adjacent DNA (portrait mobile arcade, lane-based
steering, wave/threshold pacing) but are different games. No code or
assets are shared; this stays a separate project directory and will not
be folded into sand-walker's git history.

## Resolved decisions

Former open questions, settled:

1. **True 3D vs. faux-2.5D.** True 3D (`Node3D`, real perspective camera).
   Built and shipped.
2. **Endless vs. level-based.** Level-based: hand-authored, finite,
   restart-on-fail. A short multi-level progression is design intent
   (tracked in Issues), not an endless/procedural mode.
3. **Monetization.** None, permanently. This is a personal project with
   no engagement or revenue goals — see `AGENTS.md`.
