# Blog Setup Guide

> Reproducible steps to set up this Astro + TinaCMS blog from scratch.
> Based on the [cassidoo/blahg](https://github.com/cassidoo/blahg) template.
> Last verified: 2026-06-05

---

## Prerequisites

| Tool | Version Tested | Notes |
|------|---------------|-------|
| Node.js | **v22.22.3 (LTS)** | ⚠️ Node 24+ fails — `better-sqlite3` has no prebuilt binaries |
| npm | 10.9.8 | Comes with Node 22 |
| fnm | 1.39.0 | Fast Node Manager — manages Node versions |
| Git | any recent | — |

### ⚠️ Known Issue: Node 24 + better-sqlite3

TinaCMS depends on `better-sqlite3` which requires native compilation. Node 24 is too new for prebuilt binaries, and without Visual Studio Build Tools installed, `npm install` will fail with:

```
npm error gyp ERR! find VS You need to install the latest version of Visual Studio
```

**Fix**: Use Node 22 LTS via `fnm`.

---

## Step 1: Install fnm (if not installed)

```powershell
winget install Schniz.fnm --accept-package-agreements --accept-source-agreements
```

After install, add fnm to your PowerShell profile (`$PROFILE`):

```powershell
# Add to your PowerShell profile
fnm env --use-on-cd --shell powershell | Out-String -Stream | Invoke-Expression
```

Restart your shell after this.

## Step 2: Install & use Node 22

```powershell
fnm install 22
fnm use 22
node --version  # should show v22.x.x
```

## Step 3: Clone the template

```powershell
# Option A: Clone into empty directory
git clone https://github.com/cassidoo/blahg.git .

# Option B: Use GitHub template button, then clone your repo
```

## Step 4: Remove template git history (if cloned directly)

```powershell
Remove-Item -Recurse -Force .git
git init
git branch -M main
```

## Step 5: Install dependencies

```powershell
npm install
```

Expected: ~1,348 packages, some deprecation warnings (safe to ignore).

## Step 6: Run the dev server

```powershell
npm run dev
```

This starts both:
- **Astro** at `http://localhost:4321/`
- **TinaCMS GraphQL** at `http://localhost:4001/graphql`

Access the CMS editor at: `http://localhost:4321/admin/index.html`

### Alternative command (if npm run dev doesn't work)

```powershell
npx tinacms dev -c "astro dev"
```

---

## Available Commands

| Command | Action |
|:--------|:-------|
| `npm run dev` | Start local dev server (Astro + TinaCMS) at `localhost:4321` |
| `npm run start` | Start Astro only (no TinaCMS) |
| `npm run build` | Build production site to `./dist/` |
| `npm run preview` | Preview production build locally |

---

## Configuration Checklist

After initial setup, customize these files:

- [ ] `astro.config.mjs` — Update `site` URL to your domain
- [ ] `src/settings/settings.json` — Blog name, description, etc.
- [ ] `src/components/BaseHead.astro` — Update `twitter:creator` meta tag
- [ ] `public/robots.txt` — Add your URL on line 1
- [ ] `src/components/Header.astro` — Update navigation links
- [ ] `pages/about.md` — Write your intro
- [ ] `public/` — Replace favicon and images (optional)
- [ ] `tina/config.js` — Edit post tags (optional)

---

## TinaCMS Setup (for cloud editing)

To enable the cloud CMS editor (not just local):

1. Create an account at [tina.io](https://tina.io/)
2. Create a project and connect your GitHub repo
3. Get your API keys from the Tina dashboard
4. Create `.env.development` (local) and set env vars on your host (production):

```env
TINACLIENTID=<from tina.io dashboard>
TINATOKEN=<from tina.io dashboard>
TINASEARCH=<from tina.io dashboard>
```

> ⚠️ `.env.development` is gitignored — never commit these keys.

---

## Deployment (Phase 2)

_TODO: Document deployment to chosen hosting provider._

Options:
- Netlify (template has a Deploy button)
- Vercel
- Cloudflare Pages
- Azure Static Web Apps

---

## Troubleshooting

### "Local GraphQL schema doesn't match remote"
Update TinaCMS: `npm update tinacms @tinacms/cli`
See: https://tina.io/docs/introduction/faq

### npm install fails with node-gyp errors
Switch to Node 22 LTS: `fnm use 22`

### Dev server hangs on startup
Try the manual command: `npx tinacms dev -c "astro dev"`

---

## Architecture

```
blog/
├── posts/              # Markdown blog posts (edit via CMS or directly)
├── public/             # Static assets (favicon, images, RSS styles)
├── src/
│   ├── components/     # Astro components (Header, BaseHead, etc.)
│   ├── layouts/        # Page layouts
│   ├── pages/          # Routes (index, about, posts, admin)
│   └── settings/       # Blog settings JSON
├── tina/
│   ├── config.js       # TinaCMS schema & collection definitions
│   └── __generated__/  # Auto-generated types (gitignored)
├── astro.config.mjs    # Astro configuration
└── package.json
```
