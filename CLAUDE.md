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
| **STS1** | Slay the Spire 1 — Java game. Decompile `desktop-1.0.jar` (Steam install) with IntelliJ or jadx to read full card/power/relic source. Best reference for actual game logic. |
| **STS2** | Slay the Spire 2 — Godot 4.6 / C# sequel, decompiled project at `/Users/matttemperley/Desktop/Slay the Spire 2/`. Scenes, assets and GDScript readable; C# game logic is compiled binary. |

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
- **Matt is actively learning design patterns through implementation — do not just write the
  code for him.** Instead: explain the pattern, show the shape/skeleton, then let him write it.
  Ask "want to try this part?" before filling it in. Guide, don't solve.
- **Preferred learning loop:**
  1. Point Matt at the relevant reading (GDQuest article, pattern name) *before* implementation
  2. Let him attempt it — even if rough
  3. Review what he wrote, explain what's good and why, flag issues with reasons
  4. Let him fix it himself
  5. Only fill in gaps that are genuinely blocking or out of scope
- **Timing:** surface patterns just before the phase where they become relevant — not all at once

---

## Reference Projects

| Project | Path | Notes |
|---|---|---|
| **STS2** | `/Users/matttemperley/Desktop/Slay the Spire 2/` | Godot 4.6 / C#. Scenes, assets, GDScript readable. C# logic is compiled binary. |
| **STS1** | `~/Library/Application Support/Steam/steamapps/common/SlayTheSpire/desktop-1.0.jar` | Java bytecode — decompile with IntelliJ IDEA (File → Open JAR) or [jadx](https://github.com/skylot/jadx) to read full card/power/relic source. Best reference for actual game logic. |

---

## STS2 Architecture Reference

Slay the Spire 2 (decompiled Godot 4 / C#) was studied as a direct reference for Phases 2–4.
Key patterns that map to Lemon Invasion's upcoming work:

### Scoring Pipeline → `NCardPlayQueue`
STS2 queues card plays sequentially rather than resolving instantly. For Lemon Invasion:
- The `chips × mult` scoring pass should be treated as a **sequential queue of modifier steps**,
  not a single formula evaluation. Each active card gets a "turn" to modify chips or mult.
- Keep this pipeline in `GameManager` (or a dedicated `ScoringManager`) — not on individual cards.

### Card Holder Pattern (Phase 4 shop)
STS2 uses distinct "holder" nodes for the same card in different contexts:
- Hand → Shop display → Inspection tooltip each have their own holder.
- For Lemon Invasion: build a generic `CardDisplay` scene (icon + name + cost + description)
  and reuse it in the shop grid, the "owned cards" sidebar, and any preview tooltip.
  Don't hardcode card layout per-screen.

### Run State (`NRun` → `RunState`)
STS2's `NRun` owns: deck, relics, gold, and progression. It's separate from combat state.
- Lemon Invasion's `RunState` (Phase 3) should own: `cards: Array[CardData]`, `gold: int`, `current_level: int`.
- Keep this on `GameManager` (already the autoload) rather than creating a new autoload.

### Passive Effects → NPower Pattern
STS2 powers (status effects) apply at defined moments: start of turn, on kill, end of turn.
- For cards: define when each effect fires — `on_level_start`, `on_fruit_destroyed`, `on_level_end`.
- Store these as the `effect_type` StringName already planned in `CardData`. A `match` block in
  `GameManager` per trigger point is the simplest valid implementation.

### Layered UI (Phase 1 level-complete + Phase 4 shop)
STS2 uses: `Modal → OverlayStack → GlobalUi → RoomUi`.
- For Lemon Invasion: `CanvasLayer` with a high layer index for level-complete and shop screens.
  Don't add them as children of the game world. Use a dedicated `UILayer` CanvasLayer in `main.tscn`.

### Data-Driven Resources
STS2 validates the `.tres` / `Resource` approach — card and level data are scene-independent files.
- Confirmed: stick to the plan. `LevelData.tres` and `CardData.tres` files, no hardcoded values
  in manager scripts.

### Card Rarity System
Rarity tiers confirmed from readable files: **Common, Uncommon, Rare, Ancient**, plus special
types (Curse, Event, Quest, Status). Each has its own banner material
(`/materials/cards/banners/card_banner_common_mat.tres` etc.) and frame material — rarity drives
the card's visual treatment directly via materials, not code branches.
**Not readable**: which specific card has which rarity — that's a property on the compiled C# class.
The localization JSON (`card_library.json`) only holds the display label strings ("Common", "Rare" etc.).

---

## Design Patterns Reference

Source: [GDQuest — Intro to Design Patterns](https://www.gdquest.com/tutorial/godot/design-patterns/intro-to-design-patterns/)

### Strategy Pattern → Phase 5 fire types
Each fire type is a small class extending a shared `BulletBehavior` base. `bullet.gd` holds a
`var behavior: BulletBehavior` and calls `behavior.on_hit()` — no `match` branching needed.
Cards swap the behavior at run start. Adding a new fire type = new file, no changes to bullet.gd.
See: [Strategy pattern article](https://www.gdquest.com/tutorial/godot/design-patterns/strategy/)

### Event Bus → already in use
`GameManager` autoload emitting `score_changed` is the Event Bus pattern. If card effects need
to react to distant events (e.g. fruit death triggers a card bonus), add the signal to
`GameManager` rather than creating direct connections between unrelated nodes.
See: [Event Bus article](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)

### Patterns built into Godot (no implementation needed)
- **Observer** — signals
- **Singleton** — autoloads
- **Prototype** — scenes (`duplicate()`)
- **Flyweight** — Resources (`.tres` files share data across instances)

### Patterns to skip for this project
- **Finite State Machine** — scene transitions handle game flow adequately at current scale
- **Entity-Component** — no performance benefit in GDScript; Godot nodes already give composition
- **Object Pooling** — GDScript uses reference counting, objects free instantly; not needed unless
  bullet/fruit counts cause measurable frame drops

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
