# EG-Levern Project Structure

Complete documentation of the project directory layout and component organization.

## Root Directory

```
/Users/hhartmann/p-workbench/src/EG-Levern/
├── .git/                      # Git repository metadata
├── .gitignore                 # Git ignore rules
├── .envrc                      # Direnv configuration
├── .hugo_build.lock           # Hugo build lock file (gitignored)
├── config.yaml                # Hugo site configuration
├── Makefile                   # Build automation (make serve, build, deploy)
├── README.md                  # Project README
├── CLAUDE.md                  # Project documentation for Claude
├── flake.nix                  # Nix development environment definition
├── flake.lock                 # Nix lock file (dependencies)
├── content/                   # Markdown content files
├── layouts/                   # Hugo HTML templates
├── static/                    # Static assets (images, CSS, PDFs)
├── public/                    # Generated site (from make build)
├── archetypes/                # Content templates/blueprints
├── staging/                   # Working directory for staging files
└── agents/                    # AI agent documentation (this folder)
```

## Content Directory (`/content/`)

Hugo content files in Markdown format with YAML frontmatter.

```
content/
├── _index.md                  # Homepage
├── barrierefreiheit.md        # Accessibility statement
├── datenschutz.md             # Privacy policy (Datenschutz)
├── impressum.md               # Legal notice (Impressum)
├── satzung.md                 # Bylaws/Statutes
├── jubilaeum.md               # Anniversary/Jubilee content
├── Kontaktdatenblatt.md       # Contact data sheet
├── Marktdaten.md              # Market data
└── strom/                     # Electricity section
    ├── _index.md              # Electricity section index
    └── 2024.md                # 2024 electricity data
```

### Content File Details

| File | Purpose | Language |
|------|---------|----------|
| `_index.md` | Homepage with announcements and CTAs | German |
| `barrierefreiheit.md` | Accessibility standards document | German |
| `datenschutz.md` | GDPR-compliant privacy policy | German |
| `impressum.md` | Legal notice (required in Germany) | German |
| `satzung.md` | Cooperative bylaws/articles | German |
| `jubilaeum.md` | Anniversary celebration information | German |
| `Kontaktdatenblatt.md` | Contact information sheet | German |
| `Marktdaten.md` | Electricity market data | German |
| `strom/_index.md` | Electricity section landing page | German |
| `strom/2024.md` | 2024 electricity tariffs and data | German |

## Layouts Directory (`/layouts/`)

Hugo template files using Go templating syntax.

```
layouts/
├── _default/                 # Default templates for all content types
│   ├── baseof.html          # Base template (overall page structure)
│   ├── single.html          # Template for single pages
│   └── list.html            # Template for list/section pages
├── index.html               # Homepage-specific template
├── partials/                # Reusable template components
│   └── cta.html             # Call-to-action component
└── shortcodes/              # Custom Hugo shortcodes
    ├── announcement-cards.html     # Announcement display
    ├── price-tiles.html            # Price information display
    ├── gallery.html                # Image gallery
    └── contact-card.html           # Contact information display
```

### Template Hierarchy

1. **baseof.html** - Root template with HTML structure, header, footer, navigation
2. **index.html** - Homepage-specific template (extends baseof.html)
3. **single.html** - Individual page template (extends baseof.html)
4. **list.html** - Section/archive template (extends baseof.html)
5. **Partials** - Included via `{{ partial "name" . }}`
6. **Shortcodes** - Invoked via `{{< shortcode-name >}}...{{< /shortcode-name >}}`

## Static Assets Directory (`/static/`)

Files served directly without processing by Hugo (images, CSS, PDFs).

```
static/
├── images/                   # Image files (JPG, PNG, GIF)
│   ├── header1.jpg
│   ├── liste.gif
│   ├── stromlieferungen-2018.png
│   ├── stromlieferungen-2019.png
│   └── jubilaeum/            # Anniversary photos
│       ├── IMG_7234.JPG
│       ├── IMG_6936.JPG
│       └── ...
├── portaldata/               # Portal-specific resources
│   └── 14/                   # Portal version 14
│       ├── images/           # Portal images
│       │   ├── header1.jpg
│       │   ├── header6.jpg
│       │   ├── header7.jpg
│       │   └── liste.gif
│       └── styles/           # Portal CSS
│           ├── styles.css
│           └── print.css
├── pdf/                      # PDF documents (referenced in content)
├── styles/                   # Site CSS stylesheets
├── cert/                     # Certificate files
└── desktopdefault.aspx/      # Legacy ASP.NET files (backward compatibility)
```

## Configuration

### config.yaml
Hugo site configuration:
- Site title: "EG Levern"
- Markup settings:
  - Goldmark renderer with table extension
  - Unsafe HTML rendering enabled (allows raw HTML in content)

## Archetypes Directory (`/archetypes/`)

Templates for creating new content files.

```
archetypes/
└── default.md               # Default archetype for new pages
```

## Build and Deployment

### Makefile
Automation scripts for development and deployment:
- `make serve` - Start local development server
- `make build` - Build static site to `./public/`
- `make deploy` - Build and deploy to AWS S3
- `make diff` - Compare local build with live S3 content

### Public Directory (`/public/`)
Generated static HTML/CSS/JS output from Hugo build. This is created fresh with each `make build`.

## Development Environment

### flake.nix
Nix flake definition for reproducible development environment. Includes:
- gnumake
- git
- git-crypt
- hugo
- awscli

### .envrc
Direnv configuration to automatically load Nix environment when entering directory.

## Staging Directory (`/staging/`)

Temporary working directory for:
- PDF files being prepared for publishing
- Staging area for bulk uploads
- Temporary documents awaiting integration

Current contents (staging files):
- PDF price sheets for 2026
- Announcements
- Zip archives of data

## Key Dependencies

| Component | Location | Purpose |
|-----------|----------|---------|
| Hugo | Via flake.nix | Site generation |
| Make | Via flake.nix | Build automation |
| AWS CLI | Via flake.nix | S3/CloudFront deployment |
| Git-Crypt | Via flake.nix | Secret file encryption |
| Goldmark | config.yaml | Markdown rendering |

## Deployment Infrastructure

### AWS Configuration
- **S3 Bucket**: `s3://eg-levern.de`
- **CloudFront Distribution ID**: `E1RRMW11A78TZM`
- **Credentials**: Via `AWS_SHARED_CREDENTIALS_FILE` environment variable

### Build Output
- Hugo generates files to `/public/` directory
- `make deploy` syncs `/public/` contents to S3
- CloudFront cache automatically invalidated after deployment

## File Organization Patterns

### Naming Conventions

| Pattern | Example | Usage |
|---------|---------|-------|
| lowercase | `datenschutz.md` | Single-word content files |
| PascalCase | `Kontaktdatenblatt.md` | Multi-word content files |
| UPPERCASE | `README.md`, `CLAUDE.md` | Project documentation |
| kebab-case | `announcement-cards.html` | Template and asset files |
| lowercase | `baseof.html` | Base templates |

### File Relationships

```
Content File (content/*.md)
    ↓
Hugo Processor
    ↓
Template Selection (layouts/*.html)
    ↓
Static Assets Included (static/**)
    ↓
HTML Output (public/**)
    ↓
S3 Upload via make deploy
```

## Common Locations Reference

| Task | Location |
|------|----------|
| Add new page | Create `.md` file in `/content/` |
| Update homepage | Edit `/content/_index.md` |
| Add image | Upload to `/static/images/` |
| Create shortcode | Create `.html` in `/layouts/shortcodes/` |
| Modify templates | Edit files in `/layouts/_default/` |
| Add CSS | Place in `/static/styles/` |
| View generated site | Check `/public/` after `make build` |
| Deploy changes | Run `make deploy` |
