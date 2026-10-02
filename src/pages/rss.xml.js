import rss from "@astrojs/rss";
import { getCollection } from "astro:content";
import { title, subtitle } from "../settings/settings.json";

const base = import.meta.env.BASE_URL.replace(/\/$/, "");
const site = new URL(`${base}/`, import.meta.env.SITE);

let posts = await getCollection("posts", (post) => !post.data.draft);

posts = posts
	.sort(
		(a, b) =>
			new Date(b.data.updated || b.data.added).valueOf() -
			new Date(a.data.updated || a.data.added).valueOf()
	);

export const GET = () =>
	rss({
		title: title || "",
		description: subtitle || "",
		site,
		items: posts.map((post) => {
			return {
				link: new URL(`${base}/post/${post.data.slug}/`, import.meta.env.SITE).toString(),
				title: post.data.title,
				pubDate: post.data.added,
				description: post.data.description,
				content: post.rendered.html,
				customData: `<updated>${
					post.data.updated ? post.data.updated : ""
				}</updated>`,
			};
		}),
		stylesheet: `${base}/rss-styles.xsl`,
	});
