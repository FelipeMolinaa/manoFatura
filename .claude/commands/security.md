---
description: Security audit of the code
---

Look for vulnerabilities:
- Injections: SQL, Command, XSS, Path Traversal
- Auth: weak passwords, predictable tokens, permissions
- Secrets: API keys in code, sensitive logs
- Config: debug in prod, permissive CORS, HTTPS

Classify: CRITICAL > HIGH > MEDIUM > LOW

Output: summary, vulnerabilities with severity, recommended fix.