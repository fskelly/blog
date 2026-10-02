# Blog Setup Guide

Reproducible setup for this Astro blog on Windows. Last verified: 2026-10-02.

## Prerequisites

- Git
- Node.js 22 LTS and npm
- Optional: [fnm](https://github.com/Schniz/fnm) for Node version management

The current Astro 5 toolchain is validated with Node 22. Newer Node releases
may introduce incompatible filesystem API changes, so use Node 22 for builds.

## Install Node 22 with fnm

```powershell
winget install Schniz.fnm --accept-package-agreements --accept-source-agreements
# Restart the terminal after installation.
fnm install 22
fnm use 22
node --version
```

To enable automatic Node switching in PowerShell, add this to `$PROFILE`:

```powershell
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
```

## Clone and install

```powershell
git clone https://github.com/fskelly/blog.git
Set-Location blog
fnm use 22
npm ci
```

No environment variables or external CMS credentials are required.

## Develop

```powershell
npm run dev
```

Open <http://localhost:4321/blog>. The `/blog` prefix comes from the `base`
setting in `astro.config.mjs` and matches the GitHub Pages project URL.

## Build and preview

```powershell
npm run build
npm run preview
```

The build generates the static site under `dist/` and then creates its
Pagefind search index. Open <http://localhost:4321/blog> for the preview.

## Available commands

| Command | Action |
| :------ | :----- |
| `npm run dev` | Start the Astro development server |
| `npm run start` | Start the Astro development server |
| `npm run build` | Build Astro and generate the Pagefind index |
| `npm run build:astro` | Run the equivalent Astro and Pagefind build |
| `npm run preview` | Preview the generated production site |

## Project structure

```text
blog/
|-- posts/              # Markdown blog posts
|-- public/             # Static assets, images, and RSS styles
|-- src/
|   |-- components/     # Astro components
|   |-- layouts/        # Page and post layouts
|   |-- pages/          # Site routes
|   `-- settings/       # Blog settings
|-- astro.config.mjs    # Astro and GitHub Pages configuration
`-- package.json        # Scripts and dependencies
```

## Troubleshooting

If `npm` is unavailable after installing Node, restart VS Code or refresh the
current PowerShell path:

```powershell
$env:Path = "$([Environment]::GetEnvironmentVariable('Path','Machine'));$([Environment]::GetEnvironmentVariable('Path','User'))"
```

If a production build fails under a newer Node release, switch to Node 22 and
run `npm ci` again before rebuilding.
