# Disable Copilot NES highlighting crash

The pinned `copilot-lsp` implementation asserts that Tree-sitter highlight
captures start at or after the previous capture's end. Overlapping captures
can violate that assumption while rendering a Next Edit Suggestion (NES).
Keep regular Copilot inline suggestions enabled, but disable NES until the
renderer handles overlapping captures safely.

```mermaid
flowchart TD
    A[Load Copilot configuration] --> B[Keep inline suggestions enabled]
    A --> C[Disable NES]
    C --> D[Skip NES preview rendering]
    B --> E[Continue regular inline suggestions]
```

## Assertions

- [ ] Given the Copilot configuration is loaded, expect inline suggestions
  enabled and NES disabled so a Next Edit Suggestion cannot reach the failing
  preview renderer.
