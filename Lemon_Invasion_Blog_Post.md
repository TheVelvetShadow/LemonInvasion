# Lemon Invasion — Dev Blog

A Godot port of the Scratch project "Lemonoid". An Asteroids-style shooter where the player
destroys lemons that split into smaller pieces.

---

## Entry 1 — Architecting Fruit Splitting

### The problem

The core loop of the game requires lemons to split when shot — a whole lemon breaks into two
halves, and each half breaks into two quarters. On top of that, more fruit types are planned
for the future. So the architecture needed to handle:

1. Recursive splitting (whole → halves → quarters → gone)
2. Different death animations per tier (not the same explosion every time)
3. Easy extension when new fruit types are added

### The first instinct (and why we moved on)

The original plan in `TODO.md` was to use an `is_big` boolean flag on the lemon:

```gdscript
@export var is_big: bool = true

# On death:
if is_big:
    for i in 3:
        var rock = small_lemon.instantiate()
        rock.is_big = false
        ...
```

This works for two sizes, but falls apart quickly:

- Adding a third tier means adding another flag or an integer `size` enum
- The splitting logic lives in the lemon, so every new fruit type has to reimplement it
- The death animation and the split logic are tangled together in `_die()`

### The solution: data-driven base class + virtual animation hook

The better split came from separating two distinct concerns:

- **What to spawn** — generic, belongs in the base `Fruit` class, configured via exports
- **How to die visually** — specific to each fruit tier, belongs in a subclass override

The `Fruit` base class gained two exports:

```gdscript
@export var split_scene: PackedScene  # the scene to spawn on death (leave empty = no split)
@export var split_count: int = 2
```

And `_die()` was restructured into a clear sequence:

```gdscript
func _die() -> void:
    destroyed.emit(points)   # score resolves immediately
    _spawn_splits()          # children enter the world NOW
    _play_death_animation()  # visual only — owns the queue_free()
```

`_spawn_splits()` fans the pieces out symmetrically around the current velocity direction,
so pieces always fly in a believable direction regardless of how the parent was moving:

```gdscript
func _spawn_splits() -> void:
    if not split_scene:
        return
    for i in split_count:
        var piece = split_scene.instantiate()
        get_parent().add_child(piece)
        piece.global_position = global_position
        var spread = PI / 4
        var angle = lerp(-spread, spread, float(i) / (split_count - 1))
        piece.velocity = velocity.rotated(angle) * 0.8
```

The `0.8` multiplier gives pieces slightly less speed than their parent — they slow down as
they get smaller, which reads naturally.

`_play_death_animation()` is a virtual method. In GDScript there's no `virtual` keyword —
the convention is that the base provides a sensible default (instant `queue_free()`) and
subclasses override it:

```gdscript
# Base — instant death
func _play_death_animation() -> void:
    queue_free()
```

### The scene hierarchy

Three separate scenes, each a full `Fruit` with its own sprite scale, HP, and points:

```
LemonWhole.tscn  (split_scene = LemonHalf.tscn)
LemonHalf.tscn   (split_scene = LemonQuarter.tscn)
LemonQuarter.tscn (split_scene = empty)
```

Wiring up a new split chain for a new fruit type (say, a watermelon) requires zero code
changes — just create scenes, set `split_scene` in the Inspector, and it works.

### Death animations

Each tier gets a progressively shorter, less dramatic animation:

```gdscript
# LemonWhole — punchy scale-up then fade (most visible)
func _play_death_animation() -> void:
    rotation_speed = 0
    velocity = Vector2.ZERO
    $CollisionShape2D.set_deferred("disabled", true)
    var tween = create_tween()
    tween.tween_property($Sprite2D, "scale", $Sprite2D.scale * 1.4, 0.1)
    tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.15)
    await tween.finished
    queue_free()

# LemonHalf — same pattern, smaller punch
# LemonQuarter — just a quick fade, no scale
```

One gotcha worth noting: collision must be disabled with `set_deferred()` rather than setting
it directly. Godot's physics engine doesn't allow changing collision state mid-frame (i.e.
inside a collision callback), so `set_deferred` queues the change until the end of the frame.
Without this, you get an error and the fruit can be hit again during its fade-out.

### The mental model

```
_die()  ← called when HP hits 0
  │
  ├── destroyed.emit()         ← score, always happens immediately
  ├── _spawn_splits()          ← children enter world BEFORE animation starts
  └── _play_death_animation()  ← visual only, owns the queue_free()
```

The critical insight: children are spawned before any animation plays. This means the game
logic (score + new enemies) resolves instantly and correctly, regardless of how long the
death animation runs. The animation is purely cosmetic.

---

## Entry 2 — What the Scratch Original Taught Us (and a Better Plan)

### What the approach above got wrong

The multi-scene architecture worked in theory but ran into two hard Godot physics constraints
in practice:

**Problem 1: You can't add physics nodes inside a physics callback.**

`_on_area_entered` is a physics signal. Spawning new Area2D nodes (the split pieces) from
inside it causes Godot to error:

```
Can't change this state while flushing queries. Use call_deferred() or set_deferred()
```

The fix is `_die.call_deferred()` — queue the death logic to run after the physics step.

**Problem 2: The bullet that kills the parent immediately kills the children.**

`queue_free()` is deferred — the bullet still physically exists at the moment the children
spawn in the same frame. Their `area_entered` fires against it instantly, killing 1HP children
before they move a pixel. The fix: check `area.is_queued_for_deletion()` before processing a hit.

Both of these are solvable, but they revealed the approach was fighting Godot's physics system
rather than working with it. We reverted to the working explosion animation and reconsidered.

### What the Scratch original actually does

The `.sb3` file is an assets-only pack (no logic blocks), so we couldn't read the Scratch code
directly. But the Griffpatch tutorial it's based on uses Scratch's **clone** mechanic:

- One sprite handles ALL sizes
- When hit, the sprite clones itself
- The clone reads a `size` variable and adjusts its appearance and behaviour accordingly
- At the smallest size, the clone just disappears instead of cloning again

This is elegant: no separate scenes, no separate scripts. One thing that knows what size it is.

### The Godot equivalent: self-cloning via `scene_file_path`

Godot nodes know the path to their own scene file:

```gdscript
var clone = load(scene_file_path).instantiate()
```

This means a lemon can clone itself exactly like Scratch does. Combined with a `tier` variable,
one scene handles the full split chain:

```
tier 0  →  big lemon,    scale 1.0,  hp 3,  clones 2× at tier 1
tier 1  →  half lemon,   scale 0.6,  hp 1,  clones 2× at tier 2
tier 2  →  small lemon,  scale 0.35, hp 1,  no clone → just dies
```

In `_ready()`, the tier drives everything:

```gdscript
@export var tier: int = 0

const TIER_SCALE  = [1.0,  0.6,  0.35]
const TIER_SPEED  = [150.0, 190.0, 240.0]
const TIER_HP     = [3, 1, 1]
const MAX_TIER    = 2

func _ready() -> void:
    scale = Vector2.ONE * TIER_SCALE[tier]
    speed = TIER_SPEED[tier]
    max_hp = TIER_HP[tier]
    hp = max_hp
```

And splitting becomes:

```gdscript
func _split() -> void:
    if tier >= MAX_TIER:
        return
    for i in 2:
        var clone = load(scene_file_path).instantiate()
        clone.tier = tier + 1
        get_parent().add_child(clone)
        # fan velocities apart...
```

The same two Godot constraints still apply — `call_deferred` and `is_queued_for_deletion` —
but the architecture is now much closer to the original Scratch intent. One scene, one script,
all sizes.

This is the approach to implement next.

---

## Entry 3 — Tier System and Fruit Base Class: What Got Built

### From plan to implementation

Entry 2 laid out the self-clone approach. Here's what actually shipped.

### The Fruit base class

`fruit.gd` defines all behaviour shared across fruit types:

```gdscript
extends Area2D
class_name Fruit

signal hit(points: int)       # emitted on each non-lethal bullet hit
signal destroyed(points: int) # emitted when HP reaches zero

@export var rotation_speed = 3.0
@export var speed = 150.0
@export var max_hp = 3
@export var points: int = 10
@export var hit_points: int = 1

var tier: int = 0
var max_tier: int = 0
var velocity = Vector2.ZERO
var hp: int
var split_amount = 3
var is_dying: bool = false
```

Two signals instead of one: `hit` fires on every non-lethal impact (useful for HUD feedback and audio), `destroyed` fires when the piece finally dies. `tier` and `max_tier` are plain vars, not exports — the subclass sets them in `_ready()`, the base class doesn't need to know what fruit it is.

### The `_on_area_entered` guards

```gdscript
func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("bullets") and not area.is_queued_for_deletion() and not is_dying:
```

Two guards are required:

- `is_queued_for_deletion()` — the bullet that killed the parent is still physically present when children spawn in the same frame. Without this, a 1-HP child is instantly killed before it moves a pixel.
- `is_dying` — the death animation is awaited and takes real time. Without this guard, the fruit can be hit again mid-fade.

### The death sequence

```gdscript
func _die() -> void:
    is_dying = true
    rotation_speed = 0
    velocity = Vector2.ZERO
    await _play_death_animation()
    destroyed.emit(points)
    queue_free()
```

`_play_death_animation()` is awaited — subclasses implement it as a coroutine using `await tween.finished`. The base provides a no-op `pass`. This means `destroyed` emits **after** the animation completes, and `queue_free()` is always owned by the base `_die()`, not the subclass.

`_split()` is called before `_die()` in `_on_area_entered`:

```gdscript
if hp <= 0:
    _split()
    _die()
```

Children enter the world before the animation starts. By the time any fade plays out, the next tier is already live and moving.

### Hit flash

Non-lethal hits trigger a white overbrightness flash:

```gdscript
func _flash() -> void:
    var sprite = $Sprite2D
    var tween = create_tween()
    tween.tween_property(sprite, "modulate", Color.WHITE, 0.0)
    tween.tween_property(sprite, "modulate", Color(10, 10, 10, 1), 0.05)
    tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
```

`Color(10, 10, 10, 1)` — RGB values above 1.0 overbright the sprite via HDR, punching through even near-white base colours. The sequence snaps to white instantly, blasts to overbright, then eases back.

### The Lemon subclass: 4 tiers

The plan called for 3 tiers. The implementation uses 4:

```gdscript
const TIER_SCALE  = [0.4,   0.28,  0.18,  0.11]
const TIER_SPEED  = [150.0, 190.0, 230.0, 270.0]
const TIER_HP     = [3,     2,     1,     1   ]
const TIER_POINTS = [50,    30,    20,    10  ]
```

```gdscript
func _ready() -> void:
    max_tier = TIER_SCALE.size() - 1
    scale = Vector2.ONE * TIER_SCALE[tier]
    speed = TIER_SPEED[tier]
    max_hp = TIER_HP[tier]
    points = TIER_POINTS[tier]
    super()
```

`max_tier` derives from the array length — adding a tier means adding one value to each constant array, nothing else changes.

### Death animation: tier 0 only

Only the largest lemon gets an explosion:

```gdscript
func _play_death_animation() -> void:
    if tier == 0:
        $Sprite2D.texture = load("res://Assets/explosion.png")
        $Sprite2D.scale = Vector2(2.5, 2.5)
        var tween = create_tween()
        tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.2)
        await tween.finished
```

Tiers 1–3 fall through to the base `pass` — instant disappearance. Visual weight is proportional to size, which reads naturally without needing explicit per-tier animation logic.

### One scene, all sizes

The full split chain runs through a single `lemon.tscn` scene cloning itself with `tier + 1`. With `split_amount = 3` and 4 tiers, one tier-0 lemon can cascade into up to 27 tier-3 pieces (3³ = 27).

---

## Entry 4 — FruitSpawner and Weighted Spawning

### Extracting the spawner

Spawning logic was living in `main.gd` alongside a hardcoded `lemon_mob: PackedScene` export. With more fruit types planned, that needed to move.

`FruitSpawner` is now its own node (child of main) owning the Path2D, SpawnTimer, and all spawning logic. `main.gd` is reduced to wiring:

```gdscript
# main.gd
func _ready() -> void:
    $FruitSpawner.fruit_spawned.connect(_on_fruit_spawned)

func _on_fruit_spawned(fruit: Fruit) -> void:
    fruit.dying.connect($Camera_shake.apply_shake)
    GameManager.register_fruit(fruit)
```

Adding a new fruit type now requires zero code changes — just drag its scene into `FruitSpawner.fruit_scenes` in the Inspector.

### Weighted spawn probability

Equal-probability spawning (`pick_random()`) doesn't give enough control for game balancing. The solution: each fruit scene declares its own `spawn_weight` export, and the spawner reads it.

```gdscript
# fruit.gd — weight lives on the fruit itself, next to other balance exports
@export var spawn_weight: float = 1.0
```

The spawner caches the weights at startup by doing a one-time temp-instantiate of each scene:

```gdscript
func _ready() -> void:
    for scene in fruit_scenes:
        var temp = scene.instantiate()
        _weights.append(temp.spawn_weight)
        temp.free()
```

Then `_pick_scene()` does a weighted roll:

```gdscript
func _pick_scene() -> PackedScene:
    var total = 0.0
    for w in _weights:
        total += w
    var roll = randf() * total
    var cumulative = 0.0
    for i in fruit_scenes.size():
        cumulative += _weights[i]
        if roll < cumulative:
            return fruit_scenes[i]
    return fruit_scenes.back()
```

The algorithm: multiply a 0–1 random by the total weight to get a roll, then walk the cumulative sum until the roll is exceeded. Weights are ratios, not percentages — `[3, 1]` gives 75/25, `[1, 1]` gives 50/50. The fallback `fruit_scenes.back()` guards against floating point rounding where the roll lands exactly on the total.

Keeping `spawn_weight` on the fruit rather than in the spawner means all balancing knobs (speed, HP, points, spawn rate) live in one place per fruit type.

---

*More entries to follow as development continues.*
