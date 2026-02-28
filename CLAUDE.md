# CLAUDE.md - AI Working Instructions for Starkiller Space Game

This file captures project conventions so coding agents can pick up context quickly.

## Project Overview

Starkiller Space Game is a keyboard-first, Scramble-style horizontal shooter prototype built in Godot 4.
Current focus is gameplay loop validation, tuning, and incremental feature sessions.

## Repository Structure

```
starkiller-space-game/
├── CLAUDE.md
├── README.md
├── docs/
│   ├── README.md
│   └── project-starkiller-prototype/
│       ├── README.md
│       ├── 2026-02-27-brainstorm-scramble-desktop-discovery.md
│       ├── 2026-02-28-spec-starkiller-prototype-v1.md
│       └── 2026-02-28-tasks-session-01-05-roadmap.md
├── scenes/
├── scripts/
└── assets/
```

## Docs Conventions

All documentation lives under `docs/`. Each project gets its own subdirectory.

File naming pattern:

`YYYY-MM-DD-<type>-<detail>.md`

Types:
- `brainstorm` - discovery, references, and problem framing
- `spec` - implementation contract and behavior definitions
- `tasks` - session-level execution checklist

Each project docs folder must contain `README.md` with:
- project summary
- current status
- timeline table linking docs
- naming convention reminder

When starting a new session:
1. add a new dated `tasks` file
2. update the project's timeline table

## Git Conventions

- Branch naming: `codex/<short-description>`
- Do not push directly to `main`
- Keep commits scoped and descriptive
