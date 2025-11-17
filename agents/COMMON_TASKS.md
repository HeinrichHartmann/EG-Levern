# EG-Levern Common Tasks

Step-by-step instructions for frequently performed administrative and development tasks.

## Development Environment Setup

### First Time Setup

1. **Install Nix** (if not already installed):
   ```bash
   curl -L https://nixos.org/nix/install | sh
   ```

2. **Install direnv**:
   ```bash
   # On macOS with Homebrew
   brew install direnv

   # Add direnv hook to shell config (~/.zshrc or ~/.bashrc)
   eval "$(direnv hook zsh)"
   # or for bash:
   eval "$(direnv hook bash)"
   ```

3. **Navigate to project directory**:
   ```bash
   cd /Users/hhartmann/p-workbench/src/EG-Levern
   ```

4. **Allow direnv** (this loads the development environment):
   ```bash
   direnv allow
   ```

5. **Verify environment** is loaded:
   ```bash
   which hugo    # Should show path to Hugo
   which make    # Should show path to Make
   which aws     # Should show path to AWS CLI
   ```

### Development Environment Configuration

The project uses a Nix flake for reproducible development. Key tools included:
- Hugo (static site generator)
- GNU Make (build automation)
- AWS CLI (deployment)
- Git + Git-Crypt (version control)

When you `direnv allow`, these tools become available in your shell.

## Content Management Tasks

### Create a New Page

1. **Create content file** in appropriate location:
   ```bash
   # For top-level page
   touch content/NewPage.md

   # For section page
   touch content/section/_index.md
   ```

2. **Add frontmatter**:
   ```yaml
   ---
   title: "Page Title in German"
   header_image: "image-filename.jpg"
   ---
   ```

3. **Add content** in Markdown below frontmatter

4. **Test locally**:
   ```bash
   make serve
   ```
   Visit `http://localhost:1314` and verify the new page appears

5. **Commit changes**:
   ```bash
   git add content/NewPage.md
   git commit -m "Add NewPage content"
   ```

### Edit Existing Page

1. **Open content file**:
   ```bash
   vim content/Marktdaten.md
   ```

2. **Make changes** to Markdown content and frontmatter

3. **Test changes locally**:
   ```bash
   make serve
   ```
   Refresh browser to see changes (Hugo reloads automatically)

4. **Commit changes**:
   ```bash
   git add content/Marktdaten.md
   git commit -m "Update Marktdaten content"
   ```

### Add Announcement

Announcements appear on the homepage (`content/_index.md`).

1. **Open homepage**:
   ```bash
   vim content/_index.md
   ```

2. **Find the `announcement-cards` shortcode**

3. **Add new announcement entry** (at the top for most recent):
   ```yaml
   - date: "1. Januar 2025"
     title: "Announcement Title"
     content: |
       Multi-line announcement text.
       Can include **bold**, *italic*, and [links](/path/).
   ```

4. **Test and commit**:
   ```bash
   make serve  # Verify on http://localhost:1314
   git add content/_index.md
   git commit -m "Add announcement: [Title]"
   ```

### Add or Update Pricing Information

Pricing typically appears in the `strom/` section (electricity tariffs).

1. **Open electricity section**:
   ```bash
   vim content/strom/2024.md  # or current year
   ```

2. **Add or modify `price-tiles` shortcode**:
   ```markdown
   {{< price-tiles >}}
   - title: "Grundversorgung"
     price: "36.0"
     unit: "ct./kWh"
     description: "Standard electricity tariff"
   - title: "Wärmepumpe"
     price: "31.5"
     unit: "ct./kWh"
     description: "Special rate for heat pumps"
   {{< /price-tiles >}}
   ```

3. **Test and commit**:
   ```bash
   make serve
   git add content/strom/2024.md
   git commit -m "Update 2024 electricity tariffs"
   ```

### Add Images to Content

1. **Prepare image** (optimize for web):
   ```bash
   # Compress JPEG
   jpegoptim --max=80 image.jpg

   # Convert to PNG if needed
   convert image.jpg image.png
   ```

2. **Copy to static directory**:
   ```bash
   cp image.jpg static/images/descriptive-name.jpg
   ```

3. **Reference in content**:
   ```markdown
   ![Alternative text describing image](/images/descriptive-name.jpg)

   # Or in Markdown gallery
   {{< gallery >}}
   - image: "image1.jpg"
     caption: "Photo caption"
   {{< /gallery >}}
   ```

4. **Test and commit**:
   ```bash
   git add static/images/descriptive-name.jpg
   git add content/relevant-file.md
   git commit -m "Add image: descriptive-name"
   ```

### Add PDF Document

PDFs might be tariff sheets, legal documents, etc.

1. **Prepare PDF** (ensure proper naming)

2. **Copy to static/pdf/**:
   ```bash
   cp document.pdf static/pdf/document-2024.pdf
   ```

3. **Link in content**:
   ```markdown
   [Download Price Sheet 2024](/pdf/document-2024.pdf)
   ```

4. **Commit**:
   ```bash
   git add static/pdf/document-2024.pdf
   git add content/relevant-file.md
   git commit -m "Add PDF: document-2024"
   ```

## Annual Electricity Price Update

This is a recurring task performed each year (typically in November) to update tariffs for the upcoming year.

### Prerequisites

- New price PDFs from the cooperative
- Extracted pricing data (Arbeitspreis, Grundpreis, netto prices)
- Updated announcement text

### Step-by-Step Process

1. **Sanitize and copy PDF files**:
   ```bash
   # Copy 2026 price sheets with clean filenames (no spaces, no UTF-8 umlauts)
   cp "2026 - Preisblatt-Strom-Grund-Ersatzversorgung.pdf" \
      static/pdf/2026-Preisblatt-Strom-Grund-Ersatzversorgung.pdf

   cp "2026 - Preisblatt-Strom-Wärmepumpe.pdf" \
      static/pdf/2026-Preisblatt-Strom-Waermepumpe.pdf

   cp "2026 - Preisblatt-Strom-Wärmespeicher.pdf" \
      static/pdf/2026-Preisblatt-Strom-Waermespeicher.pdf
   ```

2. **Extract pricing information from PDF**:
   ```bash
   pdftotext static/pdf/2026-Preisblatt-Strom-Grund-Ersatzversorgung.pdf -
   ```

   Look for the "Haushaltsbedarf ohne Schwachlastregelung" section:
   - Arbeitspreis (netto): e.g., 30,25 ct/kWh
   - Arbeitspreis (brutto): e.g., 36,00 ct/kWh
   - Grundpreis (netto): e.g., 121,01 EUR/Jahr
   - Grundpreis (brutto): e.g., 144,00 EUR/Jahr

3. **Create new tariff archive page** (e.g., `content/strom/2026.md`):
   - Copy from previous year's file (e.g., `2025.md`)
   - Update year in title and PDF URLs
   - Update the "Aktualisiert am" date

4. **Update main electricity page** (`content/strom/_index.md`):
   - Change heading from "Tarife 2025" → "Tarife 2026"
   - Update all PDF links from 2025 → 2026
   - Update `price-tiles` shortcode with new prices (if changed):
     ```markdown
     {{< price-tiles
         strompreis="36,00"
         stromprice_unit="Cent/kWh"
         grundpreis="144,00"
         grundpreis_unit="EUR/Jahr"
         netto_strom="30,25"
         netto_grund="121,01"
         preisblatt_url="/pdf/2026-Preisblatt-Strom-Grund-Ersatzversorgung.pdf"
     >}}
     ```
   - Update archive link from 2024 → 2025
   - Update last modified date to current date

5. **Update homepage announcements** (`content/_index.md`):
   - Add two new announcement cards at the top:
     a. Price announcement (price change or stable)
     b. Meter reading dates (Zählerablesung) for upcoming period
   - Include link to new tariff page
   - Update dates to current announcement date
   - Keep security warning (unchanged, evergreen)
   - Old announcements may be removed or archived

6. **Archive old tariffs** (keep on server, don't link):
   - Keep files from 2+ years ago (e.g., 2023, 2024) on server
   - Don't create links to them from `content/strom/_index.md`
   - This maintains SEO and accessibility if someone has old links
   - Example: 2024.md exists but is not linked from 2026 tariff page

7. **Test changes locally**:
   ```bash
   make serve
   ```
   - Visit `http://localhost:1314/strom/` and verify:
     - Current year shows as "Tarife 2026"
     - All PDF links are correct and download-able
     - Archive link points to previous year
     - Prices display correctly

   - Visit homepage and verify:
     - New announcements appear at top
     - Links to tariff page work
     - Dates are current

8. **Commit when approved**:
   ```bash
   git add content/_index.md
   git add content/strom/_index.md
   git add content/strom/2026.md
   git add static/pdf/2026-*.pdf

   git commit -m "Update electricity tariffs for 2026

   - Add 2026 price sheet PDFs
   - Create 2026 tariff archive page
   - Update homepage with 2026 announcements
   - Prices remain stable at 36.0 ct/kWh
   - Meter reading: Dec 18, 2025 - Jan 5, 2026"
   ```

9. **Deploy when ready**:
   ```bash
   make deploy
   ```

### Key Dates and Schedule

- **Typical timing**: November of the previous year
- **Effective date**: January 1st of the following year
- **PDF updates**: Available ~2 weeks before effective date
- **Announcement publish**: ~2 weeks before effective date

### File Naming Convention

All PDF filenames must follow this pattern for consistency:
```
YYYY-Preisblatt-Strom-[TYPE].pdf
```

**Types** (with umlaut sanitization):
- `Grund-Ersatzversorgung` (no suffix for base tariff)
- `Waermepumpe` (not Wärmepumpe)
- `Waermespeicher` (not Wärmespeicher)

**Examples**:
- ✅ `2026-Preisblatt-Strom-Grund-Ersatzversorgung.pdf`
- ✅ `2026-Preisblatt-Strom-Waermepumpe.pdf`
- ❌ `2026 - Preisblatt-Strom-Wärmepumpe.pdf` (spaces, umlauts)

## Build and Testing Tasks

### Build Static Site Locally

1. **Run build command**:
   ```bash
   make build
   ```

2. **Check output** in `/public/` directory:
   ```bash
   ls -la public/
   ```

3. **Verify generated HTML** is valid:
   ```bash
   # Check specific page
   head -20 public/strom/2024/index.html
   ```

### Start Development Server

1. **Start server**:
   ```bash
   make serve
   ```

2. **Server runs on**: `http://localhost:1314`

3. **Auto-reload** enabled - changes in content/layouts automatically reload in browser

4. **Stop server**: Press `Ctrl+C`

### Test Links

1. **Navigate to key pages** while dev server is running:
   - Homepage: `http://localhost:1314/`
   - Electricity section: `http://localhost:1314/strom/`
   - Legal pages: Check `datenschutz`, `impressum`, `satzung`

2. **Check all internal links** work correctly

3. **Verify images** load properly

4. **Test mobile view** using browser dev tools (Responsive Design Mode)

### Preview Production Build

1. **Build site**:
   ```bash
   make build
   ```

2. **Serve from public directory**:
   ```bash
   cd public && python3 -m http.server 8000
   ```

3. **View at**: `http://localhost:8000`

4. **Stop server**: Press `Ctrl+C`

## Deployment Tasks

### Prerequisites for Deployment

1. **AWS credentials configured**:
   ```bash
   # Set environment variable (should be in shell config)
   export AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-hhcom
   ```

2. **Verify AWS access**:
   ```bash
   aws s3 ls s3://eg-levern.de/
   ```

3. **Nix environment loaded** (via `direnv allow`)

### Deploy to Production

**WARNING**: This makes changes live to the public website.

1. **Ensure all changes are committed**:
   ```bash
   git status
   # Should show "working tree clean"
   ```

2. **Run deployment**:
   ```bash
   make deploy
   ```

   This command:
   - Builds the site (`hugo`)
   - Uploads to S3 (`aws s3 cp ./public ...`)
   - Invalidates CloudFront cache (clears CDN)

3. **Verify deployment**:
   ```bash
   # Wait 1-2 minutes for CloudFront to propagate
   curl https://eg-levern.de/
   ```

4. **Check live site** in browser:
   - Visit https://eg-levern.de
   - Verify changes appear
   - Check images and PDFs load

### Compare Local vs. Live (Dry Run)

Before deploying, compare what you have locally with what's currently on S3:

1. **Run diff command**:
   ```bash
   make diff
   ```

2. **This will**:
   - Download current S3 contents to `./public-diff/`
   - Compare with local `./public/`
   - Show differences

3. **Review differences** to ensure you're deploying intended changes

### Rollback (Emergency)

If deployment causes issues:

1. **Identify the problematic commit**:
   ```bash
   git log --oneline -10
   ```

2. **Revert to previous version**:
   ```bash
   git revert <commit-hash>
   git push
   ```

3. **Rebuild and redeploy**:
   ```bash
   make build
   make deploy
   ```

## Git and Version Control Tasks

### View Recent Changes

1. **See recent commits**:
   ```bash
   git log --oneline -10
   ```

2. **View specific commit**:
   ```bash
   git show <commit-hash>
   ```

3. **See differences since last commit**:
   ```bash
   git diff
   ```

### Commit Changes

1. **Stage all changes**:
   ```bash
   git add .
   ```

2. **Or stage specific files**:
   ```bash
   git add content/file.md
   git add static/images/new-image.jpg
   ```

3. **Commit with descriptive message**:
   ```bash
   git commit -m "Descriptive message about changes"
   ```

4. **Examples**:
   - `git commit -m "Update 2025 electricity tariffs"`
   - `git commit -m "Add anniversary event photos"`
   - `git commit -m "Fix broken link in datenschutz"`

### Push Changes to Remote

```bash
git push origin master
```

## Troubleshooting

### Hugo Not Found

**Problem**: `command not found: hugo`

**Solution**:
```bash
direnv allow
# Or manually source the environment
eval "$(direnv hook bash)"  # or zsh
```

### Port Already in Use

**Problem**: `make serve` fails with "Address already in use"

**Solution**:
```bash
# Find process using port 1314
lsof -i :1314

# Kill the process
kill -9 <PID>

# Try again
make serve
```

### AWS Credentials Not Found

**Problem**: `make deploy` fails with credentials error

**Solution**:
```bash
# Check credentials file exists
ls ~/box/secrets/aws-credentials-hhcom

# Check environment variable is set
echo $AWS_SHARED_CREDENTIALS_FILE

# Set if missing
export AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-hhcom
```

### CSS/Images Not Loading After Deploy

**Problem**: Changes deployed but CSS or images not appearing live

**Solution**:
1. Check if CloudFront invalidation completed
2. Hard refresh browser (Cmd+Shift+R on macOS, Ctrl+Shift+R on Linux/Windows)
3. Wait up to 5 minutes for CDN to propagate
4. Verify files were uploaded to S3:
   ```bash
   aws s3 ls s3://eg-levern.de/images/
   ```

### Content Not Appearing After Build

**Problem**: Changes made to content file, but not visible after `make build`

**Solution**:
1. Verify file is in `/content/` directory
2. Check file has proper YAML frontmatter (title required)
3. Verify filename follows conventions (lowercase or PascalCase)
4. Check for Hugo errors:
   ```bash
   make build 2>&1 | grep -i error
   ```
5. Manually rebuild:
   ```bash
   rm -rf public/
   make build
   ```

## Task Templates

### Generic Page Addition Template

```bash
# 1. Create file
touch content/NewSection.md

# 2. Add content
cat > content/NewSection.md << 'EOF'
---
title: "New Section Title"
---

# Heading

Content goes here.
EOF

# 3. Test
make serve

# 4. Commit
git add content/NewSection.md
git commit -m "Add NewSection page"

# 5. Deploy
make deploy
```

### Image Addition Template

```bash
# 1. Optimize image
jpegoptim --max=80 original.jpg

# 2. Copy to static
cp original.jpg static/images/image-name.jpg

# 3. Reference in content (edit relevant markdown file)
# Add: ![Description](/images/image-name.jpg)

# 4. Commit
git add static/images/image-name.jpg
git add content/file.md
git commit -m "Add image: image-name"

# 5. Deploy
make deploy
```

## Key Commands Quick Reference

| Task | Command |
|------|---------|
| Start dev server | `make serve` |
| Build site | `make build` |
| Deploy | `make deploy` |
| Compare with live | `make diff` |
| View logs | `git log --oneline` |
| Check status | `git status` |
| Stage files | `git add <file>` |
| Commit | `git commit -m "message"` |
| Push | `git push origin master` |
| Create file | `touch content/name.md` |
| Edit file | `vim content/name.md` |
