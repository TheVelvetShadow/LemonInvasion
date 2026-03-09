# Lemon Invasion — TODO

Blog post lives in `Lemon_Invasion_Blog_Post.md` — update it on significant milestones.
Project context for Claude lives in `CLAUDE.md`.

---

## Done — Phase 0 (Core Loop)

- [x] Player ship movement (left stick) and rotation (right stick)
- [x] Shooting / bullet system with cooldown and fire rate
- [x] Lemon spawning from screen edges via Path2D + Timer
- [x] Bullet-lemon collision (both destroyed)
- [x] Lemon and bullet off-screen cleanup
- [x] `Fruit` base class — signals, tier vars, `_on_area_entered` guards, `_die()` / `_play_death_animation()` await pattern, `_flash()` hit feedback
- [x] Lemon splitting — self-clone approach, 4-tier system
- [x] Hit flash (overbright tween on non-lethal hits)
- [x] FruitSpawner node — extracted from main.gd, owns Path2D/SpawnTimer, emits `fruit_spawned`
- [x] Weighted spawn probability — `spawn_weight` export on each fruit, cached weighted pick in spawner
- [x] GameManager autoload — score accumulation, `score_changed` signal
- [x] HUD — score label wired to `score_changed`
- [x] Camera shake on fruit death
- [x] Banana fruit type added
- [x] Strawberry fruit type added
- [x] Fruit base class refactor — tier arrays and `_play_death_animation()` moved to `Fruit`, subclasses reduced to data only

---

## Phase 1 — Level System

Goal: give each wave a score target. Passing it transitions to a shop placeholder.
This is the minimum structure everything else hangs off.

- [ ] Create `LevelData` resource (`res://Resources/level_data.gd` extending `Resource`)
  - Fields: `score_target: int`, `wave_duration: float`, optional `fruit_pool: Array[PackedScene]`
- [ ] `LevelManager` autoload (or extend `GameManager`)
  - Tracks: `current_level`, whether score target has been met
  - Emits `level_complete` signal when score reaches target
- [ ] Level complete screen — show score, target, "Enter Shop" button
- [ ] Shop placeholder scene (blank for now, just a "Continue" button that starts the next level)
- [ ] Wire level progression: main → level complete → shop → main (next level)
- [ ] HUD: add score target display ("Score: 240 / 500")

---

## Phase 2 — Scoring Pipeline

Goal: replace raw `score += points` with a `chips × mult` formula.
Cards slot into this pipeline, so it must exist before Phase 3.

- [ ] Refactor `GameManager`:
  - Separate `chips` accumulator from `mult` value
  - `final_score = chips * mult` computed at score time (or at level end — decide which)
  - Keep `score_changed` signal but now emit the computed value
- [ ] Decide: is score calculated continuously or only at level end?
  - Continuous (like a running total) is simpler to implement first
  - Level-end only is more Balatro-like — revisit after Phase 3 feels right
- [ ] Update HUD to show chips and mult separately if useful for debugging

---

## Phase 3 — Card Data Model

Goal: define what a card *is* and have 2–3 working cards to validate the system.

- [ ] `CardData` resource (`res://Resources/card_data.gd` extending `Resource`)
  - Fields: `card_name: String`, `description: String`, `cost: int`, `effect_type: StringName`, `effect_value: float`
- [ ] Card effects registry — a dictionary or match block in `GameManager` that maps `effect_type` to behaviour
- [ ] First cards (hardcode the data, don't build the shop yet):
  - `+1 mult` — simplest possible card, validates pipeline
  - `+10 chips per lemon destroyed` — validates event-driven cards
  - `+0.5 spawn_weight to lemons` — validates spawner-affecting cards
- [ ] `RunState` — tracks which cards are currently held (list of `CardData`)
- [ ] Cards apply their effects at the right moment (passive = on level start, triggered = on signal)

---

## Phase 4 — Shop Scene

Goal: a real between-level shop where cards are bought.

- [ ] Gold currency — earned by destroying fruit (e.g. 1 gold per fruit, bonus for tier 0)
  - Add `gold_value: int` to `Fruit`
  - `GameManager` tracks `gold`
- [ ] Shop scene (`Scenes/shop.tscn`)
  - Shows 3–4 randomly selected cards from the card pool
  - Each card shows name, description, cost
  - Buy button deducts gold, adds card to `RunState`
  - "Continue" transitions to next level
- [ ] Card pool — array of all available `CardData` resources
- [ ] Reroll mechanic (optional, costs gold) — decide after first playtest

---

## Phase 5 — Fire Types

Goal: bullet behaviour variants, unlockable via cards.

- [ ] Define fire types: Standard, Piercing (passes through fruit), Explosive (AoE on impact)
- [ ] `BulletBehavior` — a strategy that player.gd uses when calling `shoot()`
  - Could be a Resource or a simple enum + match in bullet.gd
- [ ] Cards that change fire type (e.g. "Upgrade to Piercing Shot")
- [ ] Cards that modify fire rate (e.g. "+20% fire rate")
- [ ] Visual distinction per bullet type

---

## Phase 6 — Polish

- [ ] Extract and import audio from `.sb3` (rename to `.zip` and unzip)
- [ ] Random laser sound on each shot
- [ ] Random explosion sound on fruit death
- [ ] Background music (`AudioStreamPlayer`, Autoplay, Loop)
- [ ] Explosion fade out on fruit death (tween `modulate:a`)
- [ ] High score persistence (`FileAccess`, `user://highscore.dat`)
- [ ] Main menu scene (`Scenes/menu.tscn`)
- [ ] Game over screen with final score and retry

---

## Bugs & Fixes

### Screen clamping (`player.gd:32`)
`position.clamp()` operates on the Sprite2D's local position. Movement uses `get_parent().position`.
Fix: clamp the parent Area2D instead.
```gdscript
get_parent().position = get_parent().position.clamp(bounds.position, bounds.end)
```

### `lemon_mob` null crash (historical — resolved by FruitSpawner extraction)
Was: exported `lemon_mob` var on `main.gd` crashed if not assigned in Inspector.
Fixed by extracting all spawning into `FruitSpawner`.

---

## Polish — Fruit Animations

- [ ] Improve sub-tier explosion animations — currently tiers 1+ disappear instantly.
  Add a second explosion asset (e.g. a smaller white version) and expose it on `Fruit` base
  class so each tier can play a proportionally sized effect rather than nothing.

---

## Deferred / Nice to Have

- [ ] Player-lemon collision (damage / lives system)
- [ ] Lives system (3 lives, respawn with invincibility frames)
- [ ] Difficulty scaling within a level (gradually reduce spawn interval)
- [ ] Pause menu
