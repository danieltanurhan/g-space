# Bullet System Design (Godot 4.x)

## Goals
- Replace Line3D placeholder with a proper projectile system.
- Blaster-style bolts: fast lasers, visible, slight glow (Star Wars vibe).
- Scalable: handle dozens/hundreds of projectiles without frame drops.
- Deterministic lifetime to prevent memory leaks.

## Scene Setup (Editor-side)

1. In the **FileSystem** dock create a new folder `scenes/bullets/`.
2. Right-click → **New Scene**.
3. Add node **Area3D** (rename to `Bullet`).
4. Add child **CollisionShape3D**
   - Shape: **SphereShape3D**.
   - Radius: ~0.25 (½ of visual diameter).
5. Add child **MeshInstance3D**
   - Mesh: **CylinderMesh** (radius 0.1, height 1.2) or your own bolt mesh.
   - Material:
     - **StandardMaterial3D** → Emission Color bright cyan/green (#00FFEE) and enable **Glow**.
     - OR an unshaded emissive shader for stylised energy bolts.
6. (Optional) Add child **GPUParticles3D** for a short muzzle flash or trail.
7. Save the scene as `bullet.tscn` in `scenes/bullets/`.

The scene tree should look like:
```
Bullet (Area3D)
├─ CollisionShape3D
├─ MeshInstance3D (bolt mesh)
└─ GPUParticles3D (optional)
```

## Script: `bullet.gd`
```gdscript
extends Area3D

@export var speed: float = 1200.0      # units / second
@export var lifetime: float = 2.0      # seconds before auto-free
var _velocity: Vector3

func _ready() -> void:
    _velocity = -transform.basis.z * speed   # forward points along -Z in Godot
    set_as_top_level(true)                   # detach from shooter transform

func _physics_process(delta: float) -> void:
    translate(_velocity * delta)
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()

func _on_Bullet_body_entered(body):
    # TODO: apply damage to `body` here
    queue_free()
```
Remember to connect the **body_entered** signal of the `Area3D` to `_on_Bullet_body_entered` inside the editor.

## Integrating with the Ship

1. Add an empty `Node3D` (or `Marker3D`) named `GunMount` at the muzzle position on your ship scene.
2. Expose a packed scene variable in `ship.gd`:
```gdscript
@export var BulletScene: PackedScene
@export var fire_rate_hz: float = 10.0   # shots per second
var _cooldown := 0.0
```
3. Shooting logic in `_physics_process`:
```gdscript
func _physics_process(delta):
    _cooldown = max(_cooldown - delta, 0.0)
    if Input.is_action_pressed("fire") and _cooldown == 0.0:
        shoot()
        _cooldown = 1.0 / fire_rate_hz
```
4. Implement `shoot()`:
```gdscript
func shoot() -> void:
    var bullet := BulletScene.instantiate() as Area3D
    bullet.global_transform = $GunMount.global_transform  # position + direction
    get_tree().current_scene.add_child(bullet)
```
5. Drag `bullet.tscn` into the `BulletScene` slot in the Inspector.
6. Map an input action `fire` to **Space** or **Left Mouse Button** in the project settings.

## Removing the old Line3D hack
- Delete the runtime `Line3D` creation on line 111 of `ship.gd`.
- Replace it with a call to `shoot()` (as shown above).

## Performance & Polish
- For very large bullet counts, switch to object pooling or `MultiMeshInstance3D`.
- Add a brief screen shake or sound on firing for feedback.
- Consider using a RayCast for hitscan weapons if you need instant lasers.

## Quick Checklist
- [ ] Bullet scene saved and assigned.
- [ ] GunMount correctly placed and oriented (forward = -Z).
- [ ] Input action `fire` configured.
- [ ] Old Line3D code removed.
- [ ] Test collisions and lifetime cleanup with the debugger.