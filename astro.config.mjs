import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

// https://astro.build/config
export default defineConfig({
	site: "https://fskelly.github.io",
	base: "/blog",
	integrations: [sitemap()],
	redirects: {
		"/admin": "/admin/index.html",
	},
	markdown: {
		shikiConfig: {
			theme: "material-theme-darker",
			langs: [],
		},
	},
});
