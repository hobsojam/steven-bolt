# Steven Bolt — Crowd Runner Game Spec

## Concept

A forward-auto-running "crowd" game in the Crowd City / Count Masters / Join Clash lineage. The player controls a growing/shrinking mob of followers that runs continuously down a track. The player's only input is steering left/right across a set of lanes. Skill and strategy come from choosing which math gates to run through and timing your crowd size against numeric obstacles.

This is a **separate project from sand-walker**, not a reskin of it — the core loop, camera, and input model are all different. See "Relationship to sand-walker" below.

## Core loop

1. **Auto-run forward.** The player character (and its crowd) moves down the track at a constant (or gradually increasing) speed with no manual forward/stop control.
2. **Steer.** Player drags/swipes horizontally to shift the crowd's lane position. This is the only input.
3. **Pass through gates.** Paired or tripled gates span the track width; each gate applies a math op to crowd count (`+N`, `−N`, `×N`, `÷N`). The player picks a lane and gets that gate's effect — the other gates on the same row are foregone.
4. **Clear numeric obstacles.** A wall/barrier displays a required threshold (e.g. `600`). If crowd count ≥ threshold, the crowd bursts through (optionally consuming the threshold amount as a toll). If count < threshold, the run ends (or the obstacle is impassable and forces a detour, depending on level design).
5. **Fight rival crowds (optional, v2+).** Two crowds collide and resolve 1-for-1 (or weighted) elimination over a short contact segment; survivors carry on.
6. **Finish line.** Remaining crowd count converts to score / currency / stars.

## Systems detail

### Crowd representation
- Player state is a single integer: `crowd_count`.
- Rendered units are capped for performance (e.g. draw at most ~150 instanced units regardless of true count) with a label overlay showing the real number once it exceeds what's legible on-screen.
- Crowd visual width scales roughly with `sqrt(crowd_count)`, clamped to track width; excess units stack in depth (rows) rather than overflowing sideways.

### Lanes
- 5–7 fixed lane slots (wider than sand-walker's 3, since gate rows need room for multiple simultaneous choices and the crowd itself has visual width).
- Crowd's centroid lane position is what determines which gate/obstacle segment it hits; individual follower sprites just flock loosely around that centroid.

### Gates
- Appear in rows of 2–4 across the lanes, each lane showing a different value/op.
- Types for v1: `+N`, `−N`.
- Types for v2+: `×N`, `÷N`, `%` (multiply is the highest-value/highest-risk since it compounds).
- Gate values scale with expected crowd size at that point in the level so choices stay meaningful (a `+5` gate is a trap once crowd count is in the thousands).

### Obstacles
- A wall with a visible required count. Two flavors:
  - **Toll wall:** passable if `crowd_count >= threshold`; consumes `threshold` units on pass.
  - **Checkpoint wall:** passable if `crowd_count >= threshold`; does not consume units (pure gate-check, tests whether prior gate choices were good).
- Failing a wall ends the run (hypercasual-standard fail state) — no partial credit.

### Rival crowd battles (v2+)
- Enemy crowd occupies the lane(s) ahead; on contact, both sides lose units at a fixed rate per tick until one hits zero.
- Winner's remaining count continues; if the player's crowd hits zero, run ends.

### Failure state
- `crowd_count` reaches 0 at any point (gate underflow, lost battle, or failed toll wall).

### Level structure
- Sequence of gate-rows and obstacles authored by hand (not procedural, for v1) so difficulty and "fairness" of gate math can be tuned.
- Difficulty ramps via: larger required thresholds, more deceptive gate rows (attractive-looking lane has the worse value), faster run speed.

### Camera / perspective
- Third-person chase camera behind the player, forced-perspective "road going into the distance" — this is the defining visual signature of the genre and was the main thing that made the reference screenshot look different from sand-walker's top-down framing.
- **Open question:** implement as true Godot `Node3D` (simple primitive/capsule meshes, real perspective camera) vs. a 2.5D fake-perspective trick in `Node2D` (scale + vertical-position sprites to fake depth, cheaper to build but more limited, e.g. can't bank on turns). True 3D is closer to the reference and Godot 4 handles simple low-poly 3D fine; recommend defaulting to **true 3D** unless there's a reason to stay 2D-only (e.g. wanting to reuse sand-walker's 2D pipeline/team skill).

### Controls
- Single-axis horizontal drag/swipe (touch) or A/D + mouse-drag (desktop testing). No jump, no attack button, no shoot.

## Relationship to sand-walker

| | sand-walker | steven-bolt (this spec) |
|---|---|---|
| Camera | Top-down, fixed player position | Third-person chase, forced-perspective road |
| Movement | Player fixed near bottom, world scrolls down | Player auto-runs forward continuously |
| Player power | Bullets/damage vs. enemy HP | Crowd count vs. numeric thresholds |
| Input | Lane-switch (3 lanes) | Lane-switch (5–7 lanes), same gesture family |
| Combat | Direct shooting, enemies have HP/hit-stages | Mass-vs-mass attrition (optional, v2+) |
| Engine setup | Godot 4.7, `Node2D`, 480×854 portrait | Recommend Godot 4.7, `Node3D` (see camera note), portrait |

They share genre-adjacent DNA (portrait mobile arcade, lane-based steering, wave/threshold pacing) but are different games. No code or assets are shared; this is intentionally a separate project directory and will not be folded into sand-walker's git history.

## MVP scope (v1)

- One straight track, fixed length, hand-authored.
- 5 lanes.
- Gate types: `+N`, `−N` only.
- One obstacle type: toll wall with a single numeric threshold.
- No rival-crowd battles yet.
- Placeholder capsule/blob units (no character art) — validate the math/pacing loop before investing in art.
- Single level, restart-on-fail, no meta-progression/currency yet.

## Deferred / v2+

- `×N` / `÷N` gates.
- Rival crowd battles.
- Multiple levels + level select.
- Currency/unlocks (skins for crowd units).
- Branching track sections (not just straight-line gate rows).
- Number formatting for large counts (e.g. `12.4K`, `3.1M`) once thresholds get large enough to need it.

## Open questions

1. True 3D vs. faux-2.5D perspective (see Camera section) — affects engine setup from day one.
2. Endless runner (procedural, score-chasing) vs. level-based (hand-authored, finite, star-rated)? The reference screenshot's `+99` / `600` framing reads as level-based with escalating hand-tuned numbers.
3. Any monetization intent (ads, IAP)? Not assumed here — the reference screenshot itself is an ad creative ("Überspringen" / skip button visible), not necessarily a product decision to copy.
