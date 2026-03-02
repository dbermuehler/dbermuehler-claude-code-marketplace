# dbermuehler-claude-code-marketplace

Pure configuration repository — a Claude Code Plugin Marketplace for personal productivity skills, agents, and tools.

## Repository Structure

- `.claude-plugin/marketplace.json` — registry of all plugins in this marketplace
- `plugins/<name>/` — each plugin lives in its own directory

## Component Types

| Type | Location inside a plugin |
|------|--------------------------|
| Agents | `agents/*.md` |
| Commands | `commands/*.md` |
| Skills | `skills/<name>/SKILL.md` |
| Hooks | `hooks/hooks.json` |
| MCP Servers | `.mcp.json` |
| LSP Servers | `.lsp.json` |
| Output Styles | `styles/*.md` |
| Manifest | `.claude-plugin/plugin.json` |

## Versioning

- When making changes to a plugin, bump its version in `.claude-plugin/plugin.json` following semver:
  - **patch** (0.0.x) — bug fixes, typo corrections, minor tweaks
  - **minor** (0.x.0) — new features, new components, backwards-compatible changes
  - **major** (x.0.0) — breaking changes, renames, removed functionality

## Adding a New Plugin

1. Create `plugins/<plugin-name>/` with at least one component (skill, agent, command, etc.)
2. Optionally add `.claude-plugin/plugin.json` manifest inside the plugin directory
3. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array
