---
description: Show project configuration and available vscode-init features
---

Analyze the current project and show what vscode-init configuration is active.

**Steps to follow:**

1. **Detect project type** by reading `CLAUDE.md`:
   - Look for `## Ruby`, `## Python`, `## JavaScript`, `## PHP`, `## Ruby on Rails`, `## Godot Engine` sections
   - Check for MCP configuration in `.claude/mcp.json`

2. **List available commands** by scanning `.claude/commands/`:
   - Read all .md files in the directory
   - Extract description from frontmatter or first line

3. **Show active features** by checking:
   - `.vscode/settings.json` - What language-specific settings are configured
   - Installed extensions related to the project type

4. **Display in this format:**

```
🎯 PROJECT INFORMATION

📦 Project Type:
  ✓ Ruby (with Ruby LSP, RuboCop)
  ✓ Ruby on Rails
  ✓ MCP: GitHub API

📁 vscode-init Configuration:
  • CLAUDE.md - Project context for Claude Code
  • .claude/commands/ - Custom slash commands
  • .vscode/settings.json - Language-specific settings

⚡ Available Commands:
  /document - Document code following project conventions
  /review - Code review of uncommitted changes
  /explain - Explain complex code clearly
  /security - Security audit of code
  /project-info - Show this information

🔧 Language-Specific Features:

Ruby:
  • Conventions: snake_case, YARD documentation
  • Linter: RuboCop integration
  • LSP: Shopify Ruby LSP
  • Settings: 2-space indentation, format on save

Ruby on Rails:
  • Architecture: Thin controllers, fat models
  • Patterns: Service Objects, Query Objects
  • Security: Strong Parameters, SQL placeholders

📚 Resources:
  • CLAUDE.md - Full project conventions
  • docs/vscode-init.md - vscode-init documentation
  • README.md - Project README
```

**If Godot project detected:**

```
🎯 PROJECT INFORMATION

📦 Project Type:
  ✓ Godot Engine 4.x
  • Languages: GDScript, C#

📁 vscode-init Configuration:
  • .vscode/settings.json - GDScript LSP, tabs, file associations
  • .vscode/launch.json - Debug configurations (F5, F6)
  • .vscode/tasks.json - Run/Export tasks
  • .editorconfig - Tabs for GDScript, spaces for C#
  • .gitignore - Ignores .godot/, builds/

⚡ Available Commands:
  /document - Document code following project conventions
  /review - Code review of uncommitted changes
  /explain - Explain complex code clearly
  /security - Security audit of code
  /godot-scene - Create new Godot scene with script
  /godot-script - Generate GDScript with best practices
  /godot-signal - Implement signal-based communication
  /godot-export - Export game for distribution
  /project-info - Show this information

🔧 Godot-Specific Features:

GDScript:
  • Conventions: snake_case, type hints, @export
  • Indentation: Tabs (4 spaces wide)
  • Lifecycle: _ready(), _process(), _physics_process()
  • Patterns: Signals, scene composition

Debugging:
  • F5 - Run project
  • F6 - Run current scene
  • Port 6007 - Debug server (requires Godot open)

Tasks:
  • Run Project - Execute game
  • Run Current Scene - Test single scene
  • Export Project - Build for distribution

📚 Resources:
  • CLAUDE.md - Godot patterns and conventions
  • docs/godot.md - Complete Godot guide
  • Godot Docs: https://docs.godotengine.org
```

**If Python project:**

```
🎯 PROJECT INFORMATION

📦 Project Type:
  ✓ Python
  • Linting: Pylint
  • Formatting: Black
  • Type checking: Pylance

⚡ Available Commands:
  /document - Document with Google-style docstrings
  /review - Code review with PEP 8 focus
  /explain - Explain complex code
  /security - Security audit
  /project-info - Show this information

🔧 Python-Specific Features:

Conventions:
  • Style: PEP 8
  • Docstrings: Google-style
  • Type hints: Required
  • Indentation: 4 spaces

Tools:
  • Formatter: Black (opinionated)
  • Linter: Pylint
  • LSP: Pylance (type checking)
  • Jupyter: Full notebook support

Settings:
  • format_on_save: true
  • auto_organize_imports: true
  • type_checking_mode: basic

📚 Resources:
  • CLAUDE.md - Python conventions
  • PEP 8: https://peps.python.org/pep-0008/
```

**If multiple languages detected:**

Show all detected languages with their specific features.

**If no vscode-init configuration found:**

```
ℹ️  This project doesn't appear to have vscode-init configuration.

To initialize with vscode-init:

  vscode-init . --ruby
  vscode-init . --python
  vscode-init . --javascript
  vscode-init . --godot

This will add:
  • CLAUDE.md - Project context for Claude Code
  • .claude/commands/ - Custom slash commands
  • .vscode/settings.json - Language-specific settings
  • Recommended extensions

See: https://github.com/icalvete/vscode-init
```

**Always include at the end:**

```
💡 Tips:
  • Use /document to add documentation to any code
  • Use /review before committing to catch issues
  • Check CLAUDE.md for full project conventions
  • All commands support @file mentions
```

**Format:**
- Use emojis for visual clarity
- Group related information
- Keep it concise but complete
- Make it actionable (show what user can do)
