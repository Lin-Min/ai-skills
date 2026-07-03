# cursor-skills

A lightweight Git repository for managing and sharing [Cursor Agent Skills](https://cursor.com/docs).

Clone this repo, run the install script, and skills are copied to `~/.cursor/skills/` so they are available across all your projects.

## Quick start

```bash
git clone <your-repo-url>
cd cursor-skills
./scripts/install.sh
```

Verify installation:

```bash
./scripts/list.sh
ls ~/.cursor/skills/
```

In Cursor, reference a skill by name (for example `@your-skill-name`) or let the agent discover it from the skill description.

## Available skills

| Skill | Description |
| --- | --- |
| _none yet_ | Copy `skills/_template/` to `skills/your-skill-name/` to add the first skill. See [CONTRIBUTING.md](CONTRIBUTING.md). |

Run `./scripts/list.sh` for install status.

## Scripts

| Script | Purpose |
| --- | --- |
| `./scripts/install.sh` | Install all skills to `~/.cursor/skills/` |
| `./scripts/install.sh <name>` | Install one skill |
| `./scripts/install.sh --link` | Symlink instead of copy (for local development) |
| `./scripts/install.sh --force` | Overwrite existing installation |
| `./scripts/validate.sh` | Validate skill frontmatter and conventions |
| `./scripts/list.sh` | List skills and installation status |

## Skill layout

```text
skills/
└── your-skill-name/
    ├── SKILL.md          # Required
    ├── reference.md      # Optional
    └── scripts/          # Optional utility scripts
```

Templates live in `skills/_template/` and are skipped by install scripts.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for authoring guidelines and the submission checklist.

## License

MIT — see [LICENSE](LICENSE).
