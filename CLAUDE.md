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
make deploy            # Build and deploy to AWS S3 + invalidate CDN
make diff              # Compare local build with live S3 content
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
- **Target**: AWS S3 bucket `s3://eg-levern.de`
- **CDN**: CloudFront distribution `E1RRMW11A78TZM`
- **AWS Credentials**: Configured via `AWS_SHARED_CREDENTIALS_FILE`
- **CDN Invalidation**: Manual via AWS Console or automated via `make deploy`

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