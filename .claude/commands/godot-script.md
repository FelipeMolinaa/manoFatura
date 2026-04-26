---
description: Create a GDScript with Godot best practices
---

Generate a GDScript file following Godot conventions and best practices.

**Ask the user for:**
1. Script name
2. Node type it extends (Node, Node2D, Resource, RefCounted, etc.)
3. Purpose and main functionality
4. Any signals needed
5. Any exported variables for inspector

**Generate script with:**

- Proper `extends` declaration
- Class documentation comment (`##`)
- Signal definitions with typed parameters
- `@export` variables with type hints and default values
- Private variables with underscore prefix
- `@onready` node references
- Lifecycle methods as needed
- Type hints for all functions and parameters
- Clear, descriptive function names

**Conventions to follow:**
- snake_case for variables and functions
- PascalCase for class names
- SCREAMING_SNAKE_CASE for constants
- Type hints: `var name: Type = value`
- Private: `var _internal: int = 0`
- Signals in past tense: `signal enemy_died(enemy_name: String)`

**Example:**

```gdscript
extends Node
## Health system component
##
## Manages health, damage, and healing for game entities.

signal health_changed(current: int, maximum: int)
signal damage_taken(amount: int)
signal died

const MIN_HEALTH: int = 0

@export var max_health: int = 100
@export var regeneration_rate: float = 1.0

var current_health: int = max_health:
    set(value):
        current_health = clamp(value, MIN_HEALTH, max_health)
        health_changed.emit(current_health, max_health)
        if current_health <= MIN_HEALTH:
            die()

func _ready():
    current_health = max_health

func take_damage(amount: int) -> void:
    if amount <= 0:
        return
    current_health -= amount
    damage_taken.emit(amount)

func heal(amount: int) -> void:
    if amount <= 0:
        return
    current_health += amount

func die() -> void:
    died.emit()
```
