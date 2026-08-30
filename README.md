# Steven Bolt

A Godot 4.7 3D crowd-runner in the Crowd City / Count Masters lineage:
auto-run down a straight track, steer a growing/shrinking crowd through
math gates, shoot down enemies, and break a numeric toll wall and a
whole-track horde to reach the finish.

This is a personal project with zero monetization — see `AGENTS.md`.

## Gameplay

- **Auto-run** forward down a straight track (speed ramps up over the
  run). Your only input is steering across 5 lanes.
- **Gate rows** span the track — each lane shows a `+N` or `−N`. You get
  the effect of the lane you're in; the others are foregone. The
  biggest-looking number isn't always the best lane.
- **Pickup trails** run a bonus (`+N`) down a single lane for a stretch —
  you only collect the markers you're actually in the lane for.
- **Enemy waves** are stationary enemies ahead of you. The crowd
  auto-fires as it approaches (bigger crowd = bigger volleys); any enemy
  you *don't* kill before you reach it costs you a chunk of crowd.
- **Toll wall:** pass only if your crowd is at least the shown threshold;
  passing consumes that many units.
- **Horde finale:** a full-width enemy mass. Auto-fire whittles it from a
  distance; whatever survives to contact grinds against your crowd
  one-for-one until one side is gone.
- Crowd count hits 0 at any point → run over. Reach the end with a crowd
  still standing → level complete.

### Controls

| Input | Action |
|---|---|
| `A` / Left arrow | Steer left one lane |
| `D` / Right arrow | Steer right one lane |
| Mouse drag / touch swipe | Steer (each drag threshold crossed = one lane) |
| `Enter` | Start / restart |

## Project structure

```text
scenes/main.tscn                # the only scene
scripts/
  run_controller.gd             # forward distance, level resolution, run state
  crowd_controller.gd           # crowd_count, lane steering, gate/toll math
  crowd_visual.gd               # capped MultiMesh crowd + blob contact shadow
  crowd_muzzle_flash.gd         # muzzle flashes along the crowd's front edge
  run_rules.gd                  # centralized tunable constants + pure math
  combat_rules.gd               # shot cadence / damage / breach constants
  rival_crowd_rules.gd          # mass-attrition rate
  level_one_definition.gd       # hand-authored level data
  gate_row.gd / toll_wall.gd / pickup.gd   # instant level-entry visuals
  encounter.gd                  # lifecycle for multi-frame level entries
  encounter_factory.gd          # maps an entry "kind" to an encounter
  enemy_wave_encounter.gd / enemy_wave_runtime.gd / enemy_wave_visual.gd
  horde_encounter.gd / rival_crowd_encounter.gd
  rival_crowd_runtime.gd / rival_crowd_visual.gd
  chase_camera.gd               # low chase camera, punch + shake on events
  environment_zones.gd / environment_controller.gd   # per-distance sky/prop moods
  game_hud.gd                   # crowd count, lane dots, feedback, overlays
  feedback_audio.gd             # procedurally synthesized event SFX
  vfx.gd                        # spark-burst / flash helpers
tests/run_tests.gd              # headless unit tests, no external framework
tools/generate_art_assets.gd    # procedurally builds the .glb art assets
assets/                         # models, road texture, HUD theme
GAME_SPEC.md                     # design spec: what's built + design intent
ART_SPEC.md                      # art direction / asset delivery spec
```

## Setup & development

Godot 4.7 (stable), GL Compatibility renderer, no addons or external
dependencies. See `AGENTS.md` for full setup/lint/test commands — short
version:

```sh
godot --headless --path . --import                       # import resources first
godot --path .                                           # run
godot --headless --path . --script tests/run_tests.gd     # test
gdlint .                                                   # lint (pip install "gdtoolkit==4.*")
```

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on pull requests, pushes
to `main`, and manual dispatch: imports the project, lints GDScript,
syntax-checks every script, runs the unit tests, and does a headless
smoke load.

## License

Unless otherwise noted, the code and procedural art assets in this
repository are licensed under the MIT License. See [LICENSE](LICENSE).
