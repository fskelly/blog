import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

const site = process.env.SITE_URL || "https://fskelly.com";
const base = process.env.SITE_BASE_PATH ?? "/";

function rebaseContentUrls() {
	const prefix = base.replace(/\/$/, "");
	return (tree) => {
		function visit(node) {
			for (const attribute of ["href", "src", "poster"]) {
				const value = node.properties?.[attribute];
				if (typeof value === "string") {
					if (value.startsWith("/blog/")) {
						node.properties[attribute] = `${prefix}/${value.slice(6)}`;
					} else if (value.startsWith("/assets/")) {
						node.properties[attribute] = `${prefix}${value}`;
					}
				}
			}
			for (const child of node.children || []) visit(child);
		}
		visit(tree);
	};
}

// https://astro.build/config
export default defineConfig({
	site,
	base,
	integrations: [sitemap()],
	markdown: {
		rehypePlugins: [rebaseContentUrls],
		shikiConfig: {
			theme: "material-theme-darker",
			langs: [],
		},
	},
});
