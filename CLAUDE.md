# Kairos

Personal monorepo for Agent Skills and MCP Servers.

## Structure

- `skills/` — Agent Skills (each subdirectory has SKILL.md, follows Agent Skills spec)
- `mcps/` — MCP Servers (bun workspace packages)
- `shared/` — Shared utilities between MCPs

## Conventions

- Package manager: bun
- MCP servers use TypeScript
- Skills follow the open Agent Skills format (SKILL.md with YAML frontmatter)
