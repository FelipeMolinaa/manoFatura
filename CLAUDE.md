# .

Project configured with [vscode-init](https://github.com/icalvete/vscode-init) for Claude Code.

## Project layout

```
./
├── assets/
│ ├── sprites/
│ ├── tilesets/
│ ├── sounds/
│ └── fonts/
├── scenes/
│ ├── entities/
│ ├── ui/
│ └── levels/
├── scripts/
│ ├── autoload/
│ ├── components/
│ ├── resources/
│ └── systems/
├── shaders/
└── project.godot
```

## Useful commands

```bash
# Run the game from command line
godot --path . --editor

# Run headless for testing
godot --path . --headless --script res://tests/run_tests.gd

# Export for web
godot --path . --export "HTML5" build/web/index.html

# Watch for changes and auto-reload (requires entr)
find . -name "*.gd" | entr -r godot --path . --headless
```

## Conventions

- GDScript style: Follow GDScript style guide - snake_case for variables/functions, - PascalCase for classes/nodes
- Signals: Use signals for decoupled communication between systems (inventory changes, - machine states)
- Resources: Use Godot Resources (.tres) for data definitions - machine recipes, item - properties, building stats
- Autoloads: Global systems as autoloads (EventBus, GameManager, ItemDatabase)
- Composition: Prefer composition over inheritance - create reusable components - (InventoryComponent, MachineComponent, ConveyorComponent)
- Tilemap: Use TileMap node with layered approach - floor layer, building layer, overlay - layer
- Grid system: 16x16 or 32x32 pixel grid for all placement and movement
- Save system: Use ConfigFile or Resource for save games
- Pathfinding: Use A* for conveyor routing and entity movement optimization
- Optimization: Object pooling for particles, chunk-based loading for large factories
- Documentation: Document all public methods and signals with comments

---