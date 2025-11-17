# EG-Levern Agent Documentation

This directory contains vendor-neutral documentation to enable AI agents (and human developers) to work effectively on the EG-Levern project.

## Contents

- **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - Complete overview of directory layout, file organization, and component relationships
- **[CODING_STANDARDS.md](./CODING_STANDARDS.md)** - Content conventions, formatting standards, and best practices
- **[COMMON_TASKS.md](./COMMON_TASKS.md)** - Frequently performed administrative tasks with step-by-step instructions

## Quick Facts

- **Project Type**: Static site generator (Hugo-based)
- **Language**: German content
- **Primary Tools**: Hugo, Make, AWS CLI
- **Deployment**: AWS S3 + CloudFront CDN
- **Development**: Nix flake for reproducible environment

## Getting Started

1. **Setting up**: See [COMMON_TASKS.md](./COMMON_TASKS.md#development-environment-setup)
2. **Understanding the structure**: See [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)
3. **Making changes**: See [CODING_STANDARDS.md](./CODING_STANDARDS.md)
4. **Deploying**: See [COMMON_TASKS.md](./COMMON_TASKS.md#deployment-tasks)

## Key Commands

| Task | Command |
|------|---------|
| Start dev server | `make serve` |
| Build static site | `make build` |
| Deploy to production | `make deploy` |
| Compare with live | `make diff` |

## Technology Stack

| Tool | Purpose |
|------|---------|
| Hugo 0.x+ | Static site generator |
| GNU Make | Build automation |
| AWS S3 | Static site hosting |
| CloudFront | CDN for caching and distribution |
| Nix | Development environment management |
| Git + Git-Crypt | Version control and secret management |

## Notes for Agents

- All content is in German language
- This is a content-driven site with custom Hugo shortcodes
- The site uses unsafe HTML rendering for flexibility
- Legacy files exist in `/static/desktopdefault.aspx/` for backward compatibility
- AWS credentials are required for deployment (configured via environment variable)
