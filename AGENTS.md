# Agent Notes

Guidance for coding agents working in this repo.

## Project Overview

Steven Bolt is a Godot 4.7 3D crowd-runner: the player auto-runs down a
straight track and steers between 5 lanes, growing or shrinking a crowd via
`+N`/`-N` math gates, then clearing a numeric toll wall at the end. See
`GAME_SPEC.md` for the full design spec (MVP scope, deferred v2+ features,
and the relationship to the sibling `sand-walker` project — no code or
assets are shared between them).

No monetization of any kind is planned or wanted for this project. Do not
add ad, IAP, or currency hooks, even as inert scaffolding.

## Read before working on art

**`ART_SPEC.md`** — the target look, asset list, poly/texture budgets, and
delivery format for replacing the current placeholder geometry (plain
capsules/boxes/a flat-colored plane) with real assets. Read this before
producing or wiring in any model, texture, or UI theme asset.

## Setup

Install Godot 4.7 (stable), GL Compatibility renderer. Open `project.godot`
directly — no addons or external package manager dependencies are
configured. Import resources before running headless checks:
`godot --headless --path . --import`.

## Development Commands

- Run: open `project.godot` in the Godot editor and press Play, or
  `godot --path .`. Main scene: `res://scenes/main.tscn`.
- Lint: `pip install "gdtoolkit==4.*"` then `gdlint .` (matches CI).
- Syntax check a script:
  `godot --headless --path . --check-only --script <path>`.

## Tests

`godot --headless --path . --script tests/run_tests.gd`. Run this after
touching anything under `scripts/`.

## Build

No export presets are configured yet — the project only runs in the
editor / via `godot --path .` today. An `export_presets.cfg` and CI build
job will be added once there's an MVP build worth exporting; until then
there is no packaged-build command to run.

## Architecture

- Level content is plain data, not engine logic: `scripts/level_one_definition.gd`
  returns an ordered array of gate-row/toll-wall entries keyed by distance
  along the track. Adding or retuning level content means editing this
  file, not the run/crowd controllers.
- `scripts/run_rules.gd` centralizes tunable constants (run speed, speed
  ramp, lane count/spacing, rendered-unit cap) — keep magic numbers here,
  not scattered through the controllers.
- `scripts/run_controller.gd` drives forward distance and resolves level
  entries against the player's position; `scripts/crowd_controller.gd` owns
  `crowd_count`/`current_lane` and applies gate/toll math. Keep pure math
  (gate application, threshold checks, layout math) in plain functions so
  `tests/run_tests.gd` can exercise it headlessly.

## Keep Docs And Commits Portable

Never write anything security-relevant (credentials, API keys, tokens,
internal URLs) or specific to one person's machine (absolute paths,
personal directory layouts, local tool install locations) into this
repo — including `README.md`, `AGENTS.md`, `CLAUDE.md`, commit messages,
and code comments — unless the user explicitly asks for it in a given
case. Prefer commands that assume a standard PATH-available tool over
anything tied to one contributor's environment.
