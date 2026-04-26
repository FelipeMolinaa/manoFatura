---
description: Help implement signal-based communication between nodes
---

Implement signal-based communication pattern between Godot nodes.

**Ask the user for:**
1. What event/action triggers the signal
2. Which node emits the signal (source)
3. Which node receives the signal (target)
4. What data needs to be passed (parameters)

**Generate:**

1. **Signal definition** in emitter node:
```gdscript
signal signal_name(param1: Type, param2: Type)
```

2. **Signal emission** in emitter:
```gdscript
signal_name.emit(value1, value2)
```

3. **Connection code** in receiver's `_ready()`:
```gdscript
emitter_node.signal_name.connect(_on_signal_received)
```

4. **Handler function** in receiver:
```gdscript
func _on_signal_received(param1: Type, param2: Type) -> void:
    # Handle signal
```

**Best practices to follow:**
- Name signals in past tense: `died`, `item_collected`, `health_changed`
- Use typed parameters for type safety
- Document what the signal does with comments
- Prefer signals over direct node access (`get_node()`)
- Keep signal names descriptive but concise

**Example implementation:**

```gdscript
# In Enemy.gd (emitter)
signal died(enemy_name: String, score_value: int)

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        died.emit(name, score_value)
        queue_free()

# In ScoreManager.gd (receiver)
func _ready():
    # Connect to all enemies
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.died.connect(_on_enemy_died)

func _on_enemy_died(enemy_name: String, score_value: int) -> void:
    score += score_value
    print(enemy_name, " defeated! +", score_value, " points")
```

If connecting multiple nodes, show how to use groups or iterate over children.
