# EG-Levern Coding Standards

Standards and conventions for content, templates, and configuration in the EG-Levern project.

## Content Files (Markdown)

### File Organization

- **Location**: `/content/` directory
- **Format**: Markdown with YAML frontmatter
- **Language**: German only (all content must be in German)
- **File Naming**: PascalCase for multi-word files (e.g., `Kontaktdatenblatt.md`, `Marktdaten.md`)

### Frontmatter Structure

All content files must include YAML frontmatter with these fields:

```yaml
---
title: "Page Title in German"
header_image: "image-filename.jpg"
header_attribution: |
  Attribution text (optional, can include HTML)
---
```

### Content Structure

1. **Headings**: Use standard Markdown headings (`#`, `##`, etc.)
2. **Links**: Use relative paths for internal links (e.g., `/strom/2024/`)
3. **Shortcodes**: Can use Hugo shortcodes in curly braces (see below)
4. **Lists**: Use standard Markdown lists (bullet `-` or numbered `1.`)

### Standard Shortcodes

The project includes custom shortcodes in `/layouts/shortcodes/`:

#### `announcement-cards`
For displaying dated announcements:
```markdown
{{< announcement-cards >}}
- date: "Date in German format"
  title: "Announcement Title"
  content: |
    Multi-line announcement content
    Can include **bold**, *italic*, and [links](/path/)
{{< /announcement-cards >}}
```

#### `price-tiles`
For displaying price information:
```markdown
{{< price-tiles >}}
- title: "Product Name"
  price: "0.00"
  unit: "ct./kWh"
  description: "Description text"
{{< /price-tiles >}}
```

#### `gallery`
For image galleries:
```markdown
{{< gallery >}}
- image: "image1.jpg"
  caption: "Image caption"
- image: "image2.jpg"
  caption: "Another caption"
{{< /gallery >}}
```

#### `contact-card`
For contact information:
```markdown
{{< contact-card >}}
- label: "Phone"
  value: "05745-300082"
- label: "Email"
  value: "info@eg-levern.de"
{{< /contact-card >}}
```

## Template Files (HTML/Go)

### Layout Structure

- **Base template**: `/layouts/_default/baseof.html` - Overall page structure
- **List layouts**: `/layouts/_default/list.html` - Section index pages
- **Single layouts**: `/layouts/_default/single.html` - Individual pages
- **Home layout**: `/layouts/index.html` - Homepage
- **Partials**: `/layouts/partials/` - Reusable template components

### Template Standards

1. **Go Templating**: Use Hugo's Go template syntax with `{{ }}` delimiters
2. **Variable Access**: Access page variables via `.` context (e.g., `{{ .Title }}`, `{{ .Content }}`)
3. **Conditionals**: Use `{{ if }}...{{ else }}...{{ end }}`
4. **Loops**: Use `{{ range }}...{{ end }}`

### Common Page Variables

| Variable | Description |
|----------|-------------|
| `.Title` | Page title from frontmatter |
| `.Content` | Rendered page content |
| `.Params` | Custom frontmatter parameters |
| `.Params.header_image` | Header image filename |
| `.Params.header_attribution` | Image attribution HTML |
| `.Date` | Page date (if in frontmatter) |

## Configuration

### `config.yaml`

Current settings:
- **Site title**: "EG Levern"
- **Goldmark renderer**: Enabled
- **Table extension**: Enabled (allows Markdown tables)
- **Unsafe HTML**: Enabled (allows raw HTML in content)

Modify carefully - changes affect all pages.

## Static Assets

### Directory Structure

```
/static/
├── images/           # PNG, JPG, GIF images
├── portaldata/       # Portal-specific resources
├── pdf/              # PDF documents
├── styles/           # CSS stylesheets
├── cert/             # Certificate files
└── desktopdefault.aspx/  # Legacy files
```

### Asset Linking

In content files, reference static assets with absolute paths:
```markdown
![Image alt text](/images/filename.jpg)
[Document Link](/pdf/filename.pdf)
```

## Naming Conventions

### Content Files
- **Single words**: lowercase (e.g., `impressum.md`)
- **Multiple words**: PascalCase (e.g., `Kontaktdatenblatt.md`, `Marktdaten.md`)
- **Sections**: lowercase directory with `_index.md` (e.g., `strom/_index.md`)

### Images
- **Format**: Use JPG for photos, PNG for graphics, GIF for animations
- **Naming**: Descriptive names in lowercase with hyphens (e.g., `header-image.jpg`)
- **Size**: Optimize for web (compress before uploading)

### Static Files
- **Organize by type**: images/, pdf/, styles/, etc.
- **Use descriptive names**: `stromlieferungen-2024.png` not `img1.png`

## Hugo Markdown Features

### Tables
Tables are enabled via Goldmark extension:
```markdown
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
```

### HTML in Content
Raw HTML is allowed due to `unsafe: true` setting:
```markdown
<div class="custom-class">
  Custom HTML content
</div>
```

### Internal Links
Use relative paths:
```markdown
[Link text](/strom/2024/)
[Link text](../other-section/)
```

## Best Practices

1. **Consistency**: Follow existing patterns in similar files
2. **Language**: All text, comments, and commit messages in German for content changes
3. **Testing**: Run `make serve` and visually verify changes before committing
4. **Validation**: Check links and image references work correctly
5. **Performance**: Optimize images and minimize CSS before deploying
6. **Accessibility**: Use semantic HTML and proper heading structure

## Common Mistakes to Avoid

- ❌ Mixing English and German in content
- ❌ Using absolute URLs for internal links
- ❌ Forgetting image alt text
- ❌ Leaving broken links
- ❌ Deploying without testing locally first
- ❌ Modifying Hugo config without understanding impact
