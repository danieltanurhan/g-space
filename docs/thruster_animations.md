# Ship Thruster Visuals (Godot 4.x)

## Objective
Provide the ship with dynamic thruster exhaust that reacts to acceleration, looks sci-fi, and performs well.

---

## Technique Overview
1. **GPUParticles3D** *(recommended)* – highly customizable, GPU-friendly.
2. **Flipbook `Sprite3D`** – ultra-cheap animated texture for low-end hardware.
3. **Shader-driven Cone Mesh** – advanced, single draw call, good for stylised glow.

This guide focuses on the GPUParticles3D method.

---

## Editor Setup Steps

1. Open your ship scene (`ship.tscn`).
2. Add child node **GPUParticles3D**; rename it `MainThruster`.
3. In the **Draw Pass 1** slot, assign a **QuadMesh** (`size ≈ 0.5 × 0.5`).
4. Create a new **ParticleProcessMaterial** and tweak:
   - **Emission Shape** → `Box`, Extents: `0.1, 0.1, 0.05`.
   - **Direction** → `(0, 0, -1)` (backwards).
   - **Initial Velocity** → `25 – 40` (tweak).
   - **Angle** → `8 – 10°`.
   - **Lifetime** → `0.4 s`.
   - **Scale Min / Max** → `0.6 / 1.2`.
   - **Color Ramp** → White → Light Blue → Transparent.
   - Enable **Glow** in material or rely on project Post-Process.
5. Check **Local Coordinates** so exhaust trails behind the ship.
6. Duplicate the node for side thrusters or manoeuvring jets if needed.

Node hierarchy example:
```
Ship (Node3D / RigidBody3D)
└─ MainThruster (GPUParticles3D)
```

---

## Controlling Intensity via Script

Add to `ship.gd`:
```gdscript
@onready var thruster := $MainThruster as GPUParticles3D

func _physics_process(delta):
    var throttle := clamp(acceleration_input, 0.0, 1.0)  # 0..1
    update_thruster(throttle)

func update_thruster(amount: float):
    thruster.emitting = amount > 0.05
    var mat := thruster.process_material as ParticleProcessMaterial
    mat.initial_velocity_min = 15.0 + 40.0 * amount
    mat.initial_velocity_max = 25.0 + 60.0 * amount
    mat.scale_max = lerp(0.6, 1.4, amount)
```
`acceleration_input` should be the current forward thrust value you compute from user input or physics (e.g. `Input.get_action_strength("thrust")`).

---

## Extra Polish Ideas
- **Afterburner Boost**: Spawn a one-shot `GPUParticles3D` burst when boosting.
- **Lens Flare / Bloom**: Slightly increase glow or bloom on high thrust.
- **Camera Shake**: Add subtle shake proportional to `amount` for immersion.
- **Dynamic Audio**: Pitch-shift engine sound based on thrust value.
- **Heat Distortion Shader**: Screen-space shader behind thrusters for heat haze.

---

## Performance Tips
- Keep particle count <= 256 for main thruster; reuse for LOD.
- Disable **Collision** in particles (not needed for exhaust).
- Consider culling particles when ship is far from camera.

---

## References & Further Reading
- Godot Docs: [GPUParticles3D](https://docs.godotengine.org/en/stable/tutorials/3d/particle_systems.html)
- GDC 2016 “VFX for Indies” – color ramp & timing tricks.
- Star Citizen thruster breakdown (YouTube) for artistic inspiration.