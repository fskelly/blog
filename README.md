# fskelly's blog

Welcome to my blog! I write about a bunch of things I'm interested in and tinkering with.

## What you'll find here

- **Azure & Cloud**: Deep dives into Azure, infrastructure as code (Bicep/Terraform), and cloud architecture
- **Home Automation**: Home Assistant, Shelly, ESPHome, Node-RED—all the smart home stuff
- **3D Printing**: Bambu, Creality, and general 3D printing projects and troubleshooting
- **Self-hosting & DevOps**: Running things yourself, networking, and command-line tips
- **Random tech projects**: Whatever else I'm working on or learning about

Built with [Astro](https://astro.build) and [TinaCMS](https://tina.io).

## Read the blog

[fskelly.github.io/blog](https://fskelly.github.io/blog)

## Tech stack

- **Static site**: Astro 5
- **CMS**: TinaCMS with cloud indexing
- **Hosting**: GitHub Pages
- **Content**: Markdown files with Astro frontmatter

## Local development

All commands are run from the root of the project:

| Command                 | Action                                      |
| :---------------------- | :------------------------------------------ |
| `npm install`           | Install dependencies                        |
| `npm run dev`           | Start dev server at `localhost:4321`        |
| `npm run build`         | Build production site to `./dist/`          |
| `npm run preview`       | Preview built site locally before deploying |

## Editing content

- **In TinaCMS editor**: Visit `/admin` and edit there
- **In code**: Edit `.md` files in `posts/` folder and commit

Environment variables needed (`.env.development`):
```
TINACLIENTID=<from tina.io>
TINATOKEN=<from tina.io>
TINASEARCH=<from tina.io>
```

---

And finally, thanks for reading! If you enjoyed something, feel free to reach out.

---

*Based on the [blahg](https://github.com/cassidoo/blahg) template by [cassidoo](https://github.com/cassidoo).*
