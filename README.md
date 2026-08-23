# Steven Bolt

A Godot 4.7 3D crowd-runner: steer a growing/shrinking crowd through math
gates and a toll wall, in the Crowd City / Count Masters lineage.

This is a personal project with zero monetization — see `AGENTS.md`.

## Gameplay

- Auto-runs forward down a straight track; your only input is steering
  across 5 lanes.
- Pass through gate rows: each lane applies a `+N` or `−N` to your crowd
  count — pick wisely, the biggest-looking number isn't always the best
  lane.
- Clear the toll wall with enough crowd to pass; passing costs you the
  threshold amount.
- Crowd count hits 0 at any point → run over.
- Reach the end of the track with a crowd still standing → level complete.

### Controls

| Input | Action |
|---|---|
| `A` / Left arrow | Steer left one lane |
| `D` / Right arrow | Steer right one lane |
| Mouse drag / touch swipe | Steer (crossing a distance threshold = one lane) |
| `Enter` | Start / restart |

## Project structure

```text
scenes/main.tscn              # the only scene
scripts/
  run_controller.gd           # forward distance, level resolution, run state
  crowd_controller.gd         # crowd_count, lane steering, gate/toll math
  crowd_visual.gd              # capped MultiMesh crowd rendering
  run_rules.gd                 # centralized tunable constants + pure math
  level_one_definition.gd      # hand-authored level data
  gate_row.gd / toll_wall.gd   # spawn gate/wall visuals from level data
  chase_camera.gd              # third-person chase camera
  game_hud.gd                   # crowd count + start/game-over/finished overlays
tests/run_tests.gd             # headless unit tests, no external test framework
tools/generate_art_assets.gd   # procedurally builds the .glb art assets
assets/                        # models, textures, theme
GAME_SPEC.md                    # full design spec
ART_SPEC.md                      # art direction / asset delivery spec
```

## Setup & development

Godot 4.7 (stable), GL Compatibility renderer, no addons or external
dependencies. See `AGENTS.md` for full setup/lint/test commands — short
version:

```sh
godot --path .                                           # run
godot --headless --path . --script tests/run_tests.gd     # test
gdlint .                                                   # lint (pip install "gdtoolkit==4.*")
```

## CI

GitHub Actions runs on every push and pull request: imports the project,
lints GDScript, syntax-checks every script, runs the unit tests, and does a
headless smoke load.
