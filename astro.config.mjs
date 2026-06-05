import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

// https://astro.build/config
export default defineConfig({
	site: "https://YOUR-SITE.netlify.app/", // TODO: replace with your Netlify URL after first deploy
	base: "/",
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
