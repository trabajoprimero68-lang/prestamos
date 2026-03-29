# Skill Registry — ale_gestion

Generated: 2026-03-29
Source: `~/.config/opencode/skills/`

## Agent Skills

### SDD (Spec-Driven Development)

| Skill | Trigger | Description |
|-------|---------|-------------|
| [sdd-init](./.atl/skills/sdd-init.md) | `/sdd-init`, `iniciar sdd` | Initialize SDD context |
| [sdd-explore](./.atl/skills/sdd-explore.md) | `/sdd-explore <topic>` | Investigate codebase, clarify requirements |
| [sdd-propose](./.atl/skills/sdd-propose.md) | `/sdd-propose <change>` | Create change proposal |
| [sdd-spec](./.atl/skills/sdd-spec.md) | — (orchestrator) | Write delta specifications |
| [sdd-design](./.atl/skills/sdd-design.md) | — (orchestrator) | Technical design document |
| [sdd-tasks](./.atl/skills/sdd-tasks.md) | — (orchestrator) | Task breakdown |
| [sdd-apply](./.atl/skills/sdd-apply.md) | — (orchestrator) | Implement tasks |
| [sdd-verify](./.atl/skills/sdd-verify.md) | — (orchestrator) | Validate implementation |
| [sdd-archive](./.atl/skills/sdd-archive.md) | — (orchestrator) | Archive completed change |

### Workflow

| Skill | Trigger | Description |
|-------|---------|-------------|
| [issue-creation](./.atl/skills/issue-creation.md) | New GitHub issue | Issue-first workflow |
| [branch-pr](./.atl/skills/branch-pr.md) | Creating PR | PR creation workflow |
| [judgment-day](./.atl/skills/judgment-day.md) | `judgment day` | Dual adversarial review |

### Special Purpose

| Skill | Trigger | Description |
|-------|---------|-------------|
| [go-testing](./.atl/skills/go-testing.md) | Go tests, Bubbletea | Go testing patterns |
| [skill-creator](./.atl/skills/skill-creator.md) | Creating AI skills | Create new skills |

## Project Conventions

- **AGENTS.md**: `~/.config/opencode/AGENTS.md` (global)
- **Commits**: Conventional commits, no Co-Authored-By

## Notes

- Proyecto greenfield: no hay código fuente aún
- Artifact store: Engram (MCP)
- Testing capabilities: pending (se evaluarán al agregar dependencias)
