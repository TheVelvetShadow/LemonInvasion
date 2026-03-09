# Lemon Invasion — Claude Context

Godot port of the Scratch project "Lemonoid". Asteroids-style shooter where the player destroys
fruit that splits into smaller pieces. Long-term direction: Balatro-inspired run-based progression
with a shop, modifier cards, and level score targets.

---

## Tech

- **Engine**: Godot 4
- **Language**: GDScript only (no C#)
- **Input**: Gamepad — left stick moves ship, right stick rotates, action `"player_shoot"` fires
- No external dependencies or plugins

---

## Scene & Script Map

| File | Role |
|---|---|
| `Scripts/main.gd` | Root scene. Wires FruitSpawner → GameManager and Camera_shake |
| `Scripts/game_manager.gd` | Autoload singleton. Holds score, emits `score_changed` |
| `Scripts/fruit.gd` | Base class (Area2D). Signals, tier system, splitting, death sequence |
| `Scripts/lemon.gd` | Lemon subclass. 4-tier constants, tier-0 death animation |
| `Scripts/banana.gd` | Banana subclass |
| `Scripts/fruit_spawner.gd` | Spawns fruit on a Path2D loop. Weighted pick from `fruit_scenes` array |
| `Scripts/player.gd` | Sprite2D child of Area2D. Movement, rotation, `shoot()` |
| `Scripts/bullet.gd` | Area2D. Moves on `transform.x`, group `"bullets"`, off-screen cleanup |
| `Scripts/hud.gd` | CanvasLayer. Listens to `GameManager.score_changed` |
| `Scripts/camera_shake.gd` | `apply_shake()` called on `fruit.dying` signal |

---

## Established Patterns

- **Signals for decoupling** — nodes communicate via signals, not direct references.
  Key signals: `fruit_spawned`, `hit`, `destroyed`, `dying`.
- **GameManager autoload** — global state lives here. Score today, run state in future phases.
- **Template method** — `Fruit._play_death_animation()` is a virtual hook. Base is `pass`,
  subclasses implement the coroutine. Base `_die()` always owns the `queue_free()`.
- **Data-driven via exports** — `spawn_weight`, `points`, `speed`, tier arrays are all
  exports/constants on the fruit. No hardcoded values in spawner or manager.
- **Resource files (`.tres`)** — will be used for `CardData`, `LevelData` in future phases.
  New data = new file, no new scripts.

---

## Vocabulary

| Term | Meaning |
|---|---|
| **fruit** | Any enemy (Lemon, Banana, etc.) |
| **tier** | Size/difficulty stage of a fruit (tier 0 = biggest, max_tier = smallest) |
| **split** | When a fruit dies and spawns tier+1 children |
| **run** | One full playthrough from start to game over |
| **level** | One wave with a score target — pass it to enter the shop |
| **shop** | Between-level screen where cards are bought with gold |
| **card** | A purchasable modifier that affects scoring, spawning, or firing |
| **chips** | Base score value (Balatro-inspired term used internally) |
| **mult** | Score multiplier applied to chips at scoring time |
| **gold** | Currency earned by destroying fruit, spent in the shop |
| **fire type** | A bullet behaviour variant (standard, piercing, explosive, etc.) |

---

## Scoring Formula (target)

```
final_score = (base_chips + chip_bonus) × total_mult
```

`base_chips` comes from fruit points. Cards add `+chip_bonus` or `+mult` or `×mult`.
This formula does not yet exist in code — it's the Phase 2 target.

---

## Current Phase

**Phase 0 — complete.** Core game loop: fruit spawning, splitting, tiered HP/points,
weighted spawn, score display, camera shake.

**Next: Phase 1 — Level system.**

---

## Build Strategy

| Phase | What gets built |
|---|---|
| 1 | `LevelData` resource, score target per level, level complete screen, shop placeholder |
| 2 | Scoring pipeline — refactor `GameManager` to `chips × mult` formula |
| 3 | `CardData` resource, card effects system, first 2–3 hardcoded cards |
| 4 | Shop scene — currency, random card selection, purchase |
| 5 | Fire types — bullet behaviour variants, unlockable via cards |
| 6 | Polish — audio, balance, animations |

Build bottom-up: each phase is playable and testable before starting the next.

---

## About the Developer

Matt is a junior Python dev (data engineering background) using this project to learn game dev
and software architecture. GDScript and Godot are new to him.

**How to work with this in mind:**
- Explain the *why* behind architectural suggestions, not just the what
- Prefer working code over elegant abstractions — don't over-engineer
- Flag when something could be consolidated later (e.g. a `FruitStats` lookup table) but
  don't push for it until the duplication is actually painful
- When suggesting a pattern (Strategy, Template Method, etc.) name it and briefly say what
  it means — he's learning these concepts in context
- This is a learning project first, a shipped game second

---

## Key Gotchas

- **Physics callback constraint** — can't add physics nodes (e.g. split children) inside
  `_on_area_entered`. Use `call_deferred()` or split before `_die()`.
- **Bullet lingers on kill frame** — the bullet that kills a parent is still alive when
  children spawn. Always guard with `area.is_queued_for_deletion()`.
- **Collision shape mid-frame** — use `set_deferred("disabled", true)`, not direct assignment.
- **player.gd is a Sprite2D** — its parent is the Area2D. Movement uses `get_parent().position`;
  screen clamping must also clamp `get_parent().position`, not `position`.
- **Scoring emits after animation** — `destroyed` fires after `await _play_death_animation()`.
  Children are spawned *before* `_die()` so they are live before the animation plays.
