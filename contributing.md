# Contributing to CYRAX

Thank you for your interest in improving CYRAX! We welcome community contributions that enhance quality, safety, and usability.

This project is intended for ethical, authorized security testing and educational purposes only. Do not propose, request, or submit content that facilitates illegal activity.

## How to Contribute

1. Open an Issue
- Use an issue to propose changes, report problems, or request features.
- Be clear about the problem, motivation, and expected outcome.

2. Discuss the Approach
- For significant changes, please discuss your plan in the issue first.
- This helps align scope and avoid duplicate work.

3. Submit a Pull Request (PR)
- Keep PRs focused and small when possible.
- Reference the related issue in the PR description (e.g., "Closes #123").
- Include concise testing steps or evidence.

## Project Scope and Ethics
- Only educational and authorized testing scenarios are in scope.
- No content encouraging unlawful, unethical, or harmful activity.
- Scripts should aim to be safe-by-default and clearly documented.

## Development Guidelines

### Shell Scripts (Bash)
- Use a shebang: `#!/usr/bin/env bash`.
- Prefer `set -euo pipefail` where appropriate.
- Avoid destructive defaults. Add confirmations for risky actions.
- Validate inputs and provide a `-h/--help` usage message.
- Keep output readable; log important steps and errors.
- Follow consistent naming and keep functions small and purposeful.

### Structure & Docs
- Place new tools in the most appropriate folder (e.g., `tools/attacks`, `tools/reconnaissance`, etc.).
- Add a brief header comment to each script: purpose, usage, requirements.
- Update `README.md` if user-facing behavior changes.

### Commits & Branches
- Branch naming: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
- Commit messages: short imperative subject, optional body with rationale.

## PR Checklist
- [ ] The change aligns with ethical use and project scope.
- [ ] Code is minimal, readable, and documented as needed.
- [ ] Scripts have shebang and optional `-h/--help`.
- [ ] Manual test steps (or evidence) are included.
- [ ] `README.md` or docs updated if applicable.

## Security & Responsible Disclosure
If you discover a vulnerability, please open a private discussion or contact the maintainers rather than filing a public issue first, and provide enough detail to reproduce.

## Quick Note (PT-BR)
Contribuições são bem-vindas! Abra uma issue para discutir ideias, siga este guia para PRs e mantenha o foco em uso ético e autorizado.
