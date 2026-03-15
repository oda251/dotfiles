---
name: documentation
description: This skill should be used when the user asks to "document this", "write docs", "save investigation results", "ドキュメント化して", or when handling specification, design, or investigation information that should be persisted.
---

# Documentation Skill

Persist specification, design, and investigation information as structured markdown documents.

## Process

1. Create `docs/` directory if it does not exist
2. Place documents in subdirectories by type:
   - Specification: `docs/spec/`
   - Design: `docs/design/`
   - Investigation: `docs/investigation/`
3. Include the creation date in the filename (e.g., `2026-01-01-ER-diagram.md`)
4. Check existing documents and update the diff. If the creation date or content diverges significantly, create a new file even for the same scope
5. Split files exceeding 500 lines. Rename the original file appropriately for the scope
6. Include sources (URLs, document paths, issue numbers, etc.) in a references section at the end

## Notes

- Represent diagrams with mermaid
