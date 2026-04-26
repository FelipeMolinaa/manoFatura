---
description: Local code review of uncommitted changes
---

Review changes with `git diff` checking for:
- Security: injections, secrets, permissions
- Performance: N+1 queries, inefficient loops
- Readability: naming, short functions, DRY
- Tests: coverage, edge cases

Classify as: CRITICAL > HIGH > MEDIUM > LOW

Output: positive points, issues with severity, concrete suggestions.