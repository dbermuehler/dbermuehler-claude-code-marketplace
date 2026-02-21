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

## Adding a New Plugin

1. Create `plugins/<plugin-name>/` with at least one component (skill, agent, command, etc.)
2. Optionally add `.claude-plugin/plugin.json` manifest inside the plugin directory
3. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array
