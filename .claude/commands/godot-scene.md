---
description: Create a new Godot scene with script
---

Create a new Godot scene (.tscn) and accompanying GDScript (.gd) following best practices.

**Ask the user for:**
1. Scene name (e.g., "Player", "Enemy", "MainMenu")
2. Root node type (Node2D, CharacterBody2D, Area2D, Control, Node3D, etc.)
3. Main functionality/purpose of this scene

**Generate:**

1. **Scene file (.tscn)** with:
   - Proper root node type
   - Basic node hierarchy if needed
   - Attached script reference

2. **Script file (.gd)** with:
   - Proper `extends` declaration
   - Type hints for all variables
   - `@export` variables for inspector configuration
   - Signal definitions if needed
   - Lifecycle methods (`_ready`, `_process`, or `_physics_process`)
   - Documentation comments

**Example output for "Player" scene:**

```gdscript
extends CharacterBody2D
## Player character controller
##
## Handles player movement, jumping, and input.

signal health_changed(new_health: int)
signal died

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var max_health: int = 100

var health: int = max_health:
    set(value):
        health = clamp(value, 0, max_health)
        health_changed.emit(health)
        if health <= 0:
            die()

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer

func _ready():
    pass

func _physics_process(delta):
    pass

func die():
    died.emit()
```

Place files in appropriate directories following project structure.
