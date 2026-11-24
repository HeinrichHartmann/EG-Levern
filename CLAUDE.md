# EG-Levern Project Documentation

## Overview
EG-Levern is a Hugo-based static website for a German energy cooperative (Energiegenossenschaft Levern). The site provides information about the cooperative, electricity market data, legal documents, and member services.

## Technology Stack
- **Static Site Generator**: Hugo (https://gohugo.io/)
- **Build Tool**: Make
- **Deployment**: AWS S3 + CloudFront CDN
- **Development Environment**: Nix flake
- **Content Format**: Markdown with YAML frontmatter

## Project Structure
```
/
├── config.yaml          # Hugo site configuration
├── content/             # Markdown content files
│   ├── _index.md        # Homepage content
│   ├── datenschutz.md   # Privacy policy (German)
│   ├── impressum.md     # Legal notice (German)
│   ├── satzung.md       # Bylaws/statute (German)
│   ├── jubilaeum.md     # Anniversary content
│   ├── Kontaktdatenblatt.md # Contact data sheet
│   ├── Marktdaten.md    # Market data
│   └── strom/           # Electricity-related content
│       ├── _index.md    # Electricity section index
│       └── 2024.md      # 2024 electricity data
├── layouts/             # Hugo templates
│   ├── _default/        # Default page layouts
│   ├── partials/        # Reusable template components
│   └── shortcodes/      # Custom Hugo shortcodes
├── static/              # Static assets (not processed by Hugo)
│   ├── images/          # Image files
│   ├── pdf/             # PDF documents
│   ├── styles/          # CSS stylesheets
│   ├── cert/            # Certificate files
│   └── desktopdefault.aspx/ # Legacy ASP.NET files
├── archetypes/          # Content templates for new pages
├── infra/               # OpenTofu: S3 + CloudFront for prod and dev
│   ├── README.md        # How to plan/apply, and the manual DNS steps
│   ├── providers.tf     # Version pins, S3 state backend, AWS providers
│   ├── prod.tf          # Production (imported, do not replace)
│   ├── dev.tf           # dev.eg-levern.de review environment
│   ├── variables.tf     # Inputs
│   ├── outputs.tf       # Bucket/distribution ids, DNS handover values
│   └── dev-robots.txt   # Dev-only robots.txt (Disallow: /)
└── Makefile            # Build and deployment automation
```

## Key Commands

### Development
```bash
make serve              # Start Hugo dev server on http://localhost:1314
```

### Build & Deploy
```bash
make build             # Build static site to ./public/
make deploy            # Build and deploy to PRODUCTION S3 + invalidate CDN
make diff              # Compare local build with live S3 content
```

### Dev / review environment
```bash
make build-dev         # Build with the dev baseURL
make deploy-dev        # Deploy to dev.eg-levern.de + invalidate its CDN
make diff-dev          # Compare local build with the dev bucket
```

### Infrastructure (OpenTofu)
```bash
make infra-plan        # tofu plan in ./infra
make infra-apply       # tofu apply in ./infra
```

### Hugo Commands
```bash
hugo server -D --port 1314 --bind 0.0.0.0  # Development server
hugo                                        # Build static site
```

## Configuration
- **Hugo Config**: `config.yaml`
  - Site title: "EG Levern"
  - Goldmark renderer with table extensions
  - Unsafe HTML rendering enabled

## Content Management
- All content is in German
- Uses Hugo's content organization with sections
- Markdown files with YAML frontmatter
- Static assets served from `/static/` directory

## Deployment Details

Two environments, both S3 website hosting behind CloudFront. The hosting is
defined as code in `infra/` (OpenTofu) — see `infra/README.md`.

### Production — the live site, real customers
- **Target**: AWS S3 bucket `s3://eg-levern.de`
- **CDN**: CloudFront distribution `E1RRMW11A78TZM`
- **URL**: https://eg-levern.de (+ `www.`)
- **Deploy**: `make deploy`. This goes straight to production — get explicit
  human approval for the specific change first.

### Dev — review environment
- **Target**: AWS S3 bucket `s3://dev.eg-levern.de`
- **CDN**: CloudFront distribution `E1SL20ASNAYEAH`
- **URL**: https://d2thkgludxk7z8.cloudfront.net — `dev.eg-levern.de` itself
  needs a DNS record and a certificate that only Heinrich can create
  (`infra/README.md` has the exact steps)
- **Deploy**: `make deploy-dev`. Safe to use freely; never touches prod.
- Kept out of search engines by an `X-Robots-Tag: noindex, nofollow` response
  headers policy plus a dev-only `robots.txt`. Production has no `robots.txt`.

### Shared
- **AWS Credentials**: Configured via `AWS_SHARED_CREDENTIALS_FILE`
  (`~/box/secrets/aws-credentials-hhcom`, outside the repo)
- **CDN Invalidation**: automated by `make deploy` / `make deploy-dev`
- **DNS**: manual. The deploy IAM user has no Route 53 access, so no DNS is
  managed in IaC.
- Builds use `--cleanDestinationDir`: deploys are `s3 cp --recursive`, which
  never deletes, so stale files in `./public/` would otherwise live forever.

## Infrastructure as Code
- `infra/` holds the OpenTofu configuration: `providers.tf`, `prod.tf`,
  `dev.tf`, `variables.tf`, `outputs.tf`
- Production resources are **imported**, matching what was built by hand in
  the console in 2021; `tofu plan` is expected to report no changes for them
- State lives in `s3://eg-levern-tofu-state` (private, versioned), never in
  this repo — the GitHub repository is public
- `tofu` comes from the Nix dev shell (`nix develop`)

## Development Environment
- Uses Nix flake for reproducible development environment
- Hugo and Make are the primary dependencies
- `.envrc` file for direnv integration

## Content Types
- **Homepage**: Main landing page (`_index.md`)
- **Legal Pages**: Privacy policy, legal notice, bylaws
- **Energy Data**: Electricity market information and annual reports
- **Corporate**: Contact information, anniversary content
- **Static Resources**: PDFs, images, certificates

## Notes
- This is a content-focused site with minimal interactivity
- All content appears to be in German
- Legacy ASP.NET files present in static directory (possibly for compatibility)
- Site uses Hugo's default URL structure and routing