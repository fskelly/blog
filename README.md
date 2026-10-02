# fskelly's blog

Welcome to my blog! I write about a bunch of things I'm interested in and tinkering with.

## What you'll find here

- **Azure & Cloud**: Deep dives into Azure, infrastructure as code (Bicep/Terraform), and cloud architecture
- **Home Automation**: Home Assistant, Shelly, ESPHome, Node-RED—all the smart home stuff
- **3D Printing**: Bambu, Creality, and general 3D printing projects and troubleshooting
- **Self-hosting & DevOps**: Running things yourself, networking, and command-line tips
- **Random tech projects**: Whatever else I'm working on or learning about

Built with [Astro](https://astro.build) and a customized version of the
[CapsuleX](https://github.com/wangjacks/capsule-x) theme.

The site includes responsive capsule navigation, automatic/light/dark themes,
reading progress and estimated reading time, per-post tables of contents,
category and tag archives, RSS, and Pagefind-powered search.

## Read the blog

[fskelly.github.io/blog](https://fskelly.github.io/blog)

## Tech stack

- **Static site**: Astro 5
- **Theme**: Customized CapsuleX
- **Search**: Pagefind
- **Hosting**: GitHub Pages
- **Content**: Markdown files with Astro frontmatter

## Prerequisites

- Git
- Node.js 22 LTS and npm

Node 22 is recommended for the current Astro 5 toolchain. On Windows, the
recommended setup is
[fnm](https://github.com/Schniz/fnm):

```powershell
winget install Schniz.fnm
# Restart the terminal after winget completes.
fnm install 22
fnm use 22
node --version
npm --version
```

See [SETUP.md](SETUP.md) for more detailed Windows setup notes.

## First-time setup

```powershell
git clone https://github.com/fskelly/blog.git
Set-Location blog
fnm use 22
npm ci
```

## Develop locally

Start the Astro development server:

```powershell
npm run dev
```

`npm run start` is an alias for the same development server.

```powershell
npm run start
```

Because this repository is a GitHub Pages project site, Astro uses `/blog` as
its base path. Open:

- Site: <http://localhost:4321/blog>
- RSS: <http://localhost:4321/blog/rss.xml>
- Search: <http://localhost:4321/blog/search>

Stop a development or preview server with `Ctrl+C`.

### Windows: npm is not recognized

After installing Node with winget, restart VS Code so new terminals inherit the
updated `PATH`. To refresh an already-open PowerShell session immediately:

```powershell
$env:Path = "$([Environment]::GetEnvironmentVariable('Path','Machine'));$([Environment]::GetEnvironmentVariable('Path','User'))"
node --version
npm --version
```

## Edit content

Edit or add Markdown files below `posts/`.

Every Markdown post must include the required frontmatter before Astro can
build it:

```yaml
---
title: Example post
slug: example-post
description: A short summary of the post.
tags:
  - example
categories:
  - personal
added: 2026-10-02T00:00:00.000Z
---
```

Do not leave empty `.md` files under `posts/`; Astro treats each one as a
content entry and rejects it when the required metadata is missing.

Set `draft: true` while a post is in progress. Drafts can be opened directly
when `npm run start` or `npm run dev` is running, but they are excluded from
production routes, post lists, search, categories, tags, and RSS.

### Add images to posts

Store post images under a descriptive folder in `public/assets/`, for example:

```text
public/assets/2026/example-post/image.png
```

Files under `public/` are served from the site root. Because this site uses the
`/blog` base path, embed that image with:

```markdown
![Useful alternative text](/blog/assets/2026/example-post/image.png)
```

To make the image clickable and open the full-size file:

```markdown
[![Useful alternative text](/blog/assets/2026/example-post/image.png)](/blog/assets/2026/example-post/image.png)
```

Use meaningful alternative text, optimize large images, and crop or redact
private details before publishing.

## Build and test

Run the production build and search indexer:

```powershell
npm run build
```

This builds the static site into `dist/` and creates the Pagefind search index.
The Astro production build is the repository's primary compile and content
validation; there is currently no separate unit-test or lint script.
`npm run build:astro` remains available as an equivalent command.

Preview the generated production output:

```powershell
npm run preview
```

Then verify these routes manually:

1. <http://localhost:4321/blog> renders the home page and theme controls.
2. Open a post and check its table of contents, reading progress, and navigation.
3. <http://localhost:4321/blog/search> returns results.
4. <http://localhost:4321/blog/rss.xml> renders the styled RSS feed.
5. Check a narrow browser viewport and both light and dark themes.

Optional response checks from another PowerShell terminal:

```powershell
(Invoke-WebRequest http://localhost:4321/blog).StatusCode
(Invoke-WebRequest http://localhost:4321/blog/rss.xml).StatusCode
Test-Path .\dist\pagefind\pagefind.js
```

All three checks should return `200`, `200`, and `True`, respectively.

## Commit and push

Review and stage only the intended files:

```powershell
git status --short
git diff --check
git diff
git add -p
git add THIRD_PARTY_NOTICES.md src/components/TableOfContents.astro
git diff --cached
git commit -m "Update blog theme"
```

Stage any new post or asset files explicitly by path before committing.

Synchronize with `main` before publishing, then push:

```powershell
git pull --rebase origin main
git push origin main
```

If the rebase reports conflicts, resolve them, stage the resolved files, and
run `git rebase --continue` before pushing. Never commit environment files,
credentials, or unrelated local files.

## Deployment

Every push to `main` triggers
[.github/workflows/deploy.yml](.github/workflows/deploy.yml). The workflow:

1. Installs dependencies with Node.js 22 and `npm ci`.
2. Builds Astro and generates the Pagefind index.
3. Uploads `dist/` and deploys it to GitHub Pages.

Monitor the workflow in the repository's **Actions** tab. After it succeeds,
verify <https://fskelly.github.io/blog> and its RSS and search pages. The
workflow can also be started manually with **Actions > Deploy to GitHub Pages >
Run workflow**.

## Command reference

| Command | Action |
| :------ | :----- |
| `npm ci` | Install the exact locked dependency versions |
| `npm run dev` | Start the Astro development server |
| `npm run start` | Start the Astro development server |
| `npm run build` | Build Astro and generate the Pagefind index |
| `npm run build:astro` | Run the equivalent Astro and Pagefind build |
| `npm run preview` | Preview the existing production build |

---

And finally, thanks for reading! If you enjoyed something, feel free to reach out.

---

Based on the [blahg](https://github.com/cassidoo/blahg) template by
[cassidoo](https://github.com/cassidoo), with theme code adapted from
[CapsuleX](https://github.com/wangjacks/capsule-x). See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for licensing details.
