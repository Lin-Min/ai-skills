# Contributing

Thank you for contributing AI agent skills to this repository.

## Create a new skill

1. Copy the template:

```bash
cp -R skills/_template skills/your-skill-name
```

2. Edit `skills/your-skill-name/SKILL.md`:
   - Set `name` to match the directory name (lowercase, hyphens, max 64 chars)
   - Write a specific third-person `description` that includes both **what** the skill does and **when** to use it
   - Keep the main file concise; move details to `reference.md` or `scripts/`

3. Validate before opening a PR:

```bash
./scripts/validate.sh your-skill-name
```

4. Update the skill list in [README.md](README.md).

## SKILL authoring checklist

### Core quality

- [ ] `description` is specific and includes key trigger terms
- [ ] `description` includes both WHAT and WHEN
- [ ] `description` is written in third person
- [ ] `SKILL.md` body is under 500 lines
- [ ] Terminology is consistent throughout
- [ ] Examples are concrete, not abstract

### Structure

- [ ] File references are one level deep (from `SKILL.md` to sibling files)
- [ ] Progressive disclosure is used for long content
- [ ] Workflows have clear steps
- [ ] No time-sensitive information without a deprecation note

### Scripts (if included)

- [ ] Scripts solve real problems instead of deferring work
- [ ] Required packages are documented
- [ ] Error handling is explicit and helpful
- [ ] Paths use forward slashes, not Windows backslashes

## Storage locations (for users)

| Type | Path | Scope |
|------|------|-------|
| Personal | `~/.cursor/skills/skill-name/` | Available across all projects |
| Project | `.cursor/skills/skill-name/` | Shared with anyone using the repository |

This repository installs skills to the **personal** location by default.

**Do not** install skills into `~/.cursor/skills-cursor/`. That directory is reserved for Cursor built-in skills.

## Pull request guidelines

- One skill per PR when possible
- Run `./scripts/validate.sh` locally
- Include a short note in the PR describing trigger scenarios for the skill
- Update README skill table
