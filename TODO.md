# Lemon Invasion — TODO & Tutorial

Godot port of the Scratch project "Lemonoid". Asteroids-style shooter where the player
destroys lemons that split into smaller pieces. Assets (sprites, audio) are bundled in
`Lemonoid Assets (part 1 & 2).sb3` (a ZIP — extract with any zip tool to access files).

---

## Done

- [x] Player ship movement (left stick) and rotation (right stick)
- [x] Shooting / bullet system with cooldown and fire rate
- [x] Lemon spawning from screen edges via Path2D + Timer
- [x] Bullet-lemon collision (both destroyed)
- [x] Lemon and bullet off-screen cleanup

---

## Bug Fixes

### Screen clamping (`player.gd:32`)
The clamping line operates on the `Sprite2D`'s local position, but movement uses
`get_parent().position` (the parent `Area2D`). Fix by clamping the parent instead:
```gdscript
# Replace line 32 in player.gd:
get_parent().position = get_parent().position.clamp(bounds.position, bounds.end)
```

### `lemon_mob` null crash (`main.gd:17`)
The exported `lemon_mob` variable must be assigned in the Inspector or the game crashes
after 1.5 s. Select the `main` node → Inspector → assign `Scenes/lemon.tscn` to **Lemon Mob**.
As a safety net, add a guard in the script:
```gdscript
if lemon_mob == null:
    return
var lemon = lemon_mob.instantiate()
```

---

## Gameplay

### Two lemon sizes
The Scratch project has two enemy costumes: `BIG` and `rock`. The plan is one scene
with a size parameter rather than two separate scenes.

1. Add `@export var is_big: bool = true` to `lemon.gd`.
2. In `_ready()`, scale the node: `scale = Vector2(1, 1) if is_big else Vector2(0.5, 0.5)`.
3. Adjust `lemon_speed` based on size — small lemons should move faster.

### Lemon splitting
When a BIG lemon is shot it should spawn 2–3 small rock lemons.

1. Add `@export var small_lemon: PackedScene` to `lemon.gd` (assign in Inspector).
2. In `_on_area_entered`, before `queue_free()`, check `if is_big`:
```gdscript
if is_big:
    for i in 3:
        var rock = small_lemon.instantiate()
        get_parent().add_child(rock)
        rock.position = position
        rock.is_big = false
        var angle = randf_range(0, TAU)
        rock.velocity = Vector2.RIGHT.rotated(angle) * rock.lemon_speed
```

### Player-lemon collision
`lemon.gd` currently only checks for bullets. Add player detection:

1. Add the player `Area2D` to a group called `"player"` (select it in the scene → Node tab → Groups).
2. In `lemon.gd _on_area_entered`:
```gdscript
elif area.is_in_group("player"):
    area.get_parent().emit_signal("hit")  # or call a die() function directly
    queue_free()
```

### Lives system
1. Add `var lives = 3` to `main.gd`.
2. Connect a `hit` signal from the player to `main.gd`.
3. On hit: decrement lives, update HUD, respawn or trigger game over.

### Player respawn + invincibility frames
After dying, the player should briefly flash and be immune to hits.

1. Add `var invincible = false` to `player.gd`.
2. On death: set `invincible = true`, play a flash animation (use `AnimationPlayer` or a `Tween`), then set `invincible = false` after ~2 s.
3. In the lemon collision check, also guard with `if not area.get("invincible")`.

### Score system
1. Add `var score = 0` to `main.gd`.
2. Emit a signal from `lemon.gd` when destroyed, carrying a point value:
```gdscript
signal destroyed(points)
# in _on_area_entered:
destroyed.emit(200 if is_big else 500)
```
3. Connect that signal in `main.gd` and add the value to `score`.

### Difficulty scaling
In `main.gd _process`, gradually reduce the timer's `wait_time`:
```gdscript
$LemonSpawnTimer.wait_time = max(0.4, $LemonSpawnTimer.wait_time - 0.0001 * delta)
```

---

## Audio

No audio has been imported yet. All files are inside the `.sb3` (it's a ZIP).

**How to extract:** rename `.sb3` to `.zip` and unzip, or run:
```bash
unzip "Lemonoid Assets (part 1 & 2).sb3" -d lemon_assets
```

Then drag the files into `Assets/Audio/` in the Godot FileSystem panel.

| File in .sb3 | Description |
|---|---|
| `1969292b…mp3` | `n-Dimensions` — main theme (background music) |
| `83a9787d…wav` | `Laser_Shoot7` |
| `83c36d80…wav` | `Laser_Shoot2` |
| `8ca40364…wav` | `Laser_Shoot4` |
| `b958b430…wav` | `Laser_Shoot16` |
| `9a61b908…wav` | `Explosion6` |
| `a60fb0ff…wav` | `Explosion2` |
| `61249ebd…wav` | `Explosion18` |

**How to play a random sound in Godot:**
1. Add an `AudioStreamPlayer` node to the scene.
2. Store your sounds in an array and pick one at random:
```gdscript
var laser_sounds = [preload("res://Assets/Audio/laser1.wav"), ...]
func play_laser():
    $AudioStreamPlayer.stream = laser_sounds.pick_random()
    $AudioStreamPlayer.play()
```

- [ ] Extract and import audio from `.sb3`.
- [ ] Random laser sound on each shot.
- [ ] Random explosion sound on lemon death.
- [ ] Background music — add an `AudioStreamPlayer` (Autoplay on, Loop on) with the main theme.

---

## UI / Screens

### HUD
1. Add a `CanvasLayer` node to `main.tscn` (so it stays fixed on screen).
2. Inside it, add `Label` nodes for score and lives.
3. Update them from `main.gd` whenever score/lives change:
```gdscript
$HUD/ScoreLabel.text = "Score: %d" % score
$HUD/LivesLabel.text = "Lives: %d" % lives
```

### Main menu
1. Create a new scene `Scenes/menu.tscn` with a `Control` root.
2. Add a title label and a Start button.
3. On button press: `get_tree().change_scene_to_file("res://Scenes/main.tscn")`.

### Game over screen
1. Add a hidden `Panel` (or `CanvasLayer`) to `main.tscn` called `GameOver`.
2. Show it when lives reach 0, display the final score, and add a Retry button:
```gdscript
func game_over():
    get_tree().paused = true
    $GameOver.show()
```
3. Retry button: `get_tree().reload_current_scene()`.

### Pause menu
1. Listen for a pause input action (add one in **Project → Input Map**).
2. Toggle `get_tree().paused` and show/hide a pause panel.
   - Nodes that should still run while paused (e.g. UI) need `process_mode = Always`.

---

## Polish

- [x] **Explosion sprite on death** — swap Sprite2D texture to `explosion.png` in `_die()`, stop movement, then `queue_free()` after a short delay.
- [ ] **Explosion fade out** — after swapping to the explosion texture, tween the sprite's `modulate` alpha from 1 to 0 over ~0.5 s before freeing.
- [ ] **Screen shake on death** — use a `Tween` to rapidly offset the `Camera2D` position then reset it.
- [ ] **High score persistence** — use `FileAccess` to read/write a score file:
```gdscript
func save_score(s):
    var f = FileAccess.open("user://highscore.dat", FileAccess.WRITE)
    f.store_var(s)
```
