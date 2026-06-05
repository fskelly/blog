import { defineCollection, z } from "astro:content";

import { glob } from "astro/loaders";

const posts = defineCollection({
	loader: glob({
		pattern: "**/*.md",
		base: "./posts",
		generateId: ({ entry }) => entry.replace(/\.md$/, ""),
	}),
	schema: z.object({
		title: z.string(),
		slug: z.string(),
		description: z.string(),
		added: z.union([z.string(), z.date()]),
		updated: z.union([z.string(), z.date()]).optional(),
		tags: z.array(z.string()),
		categories: z.array(z.string()).optional(),
	}),
});

export const collections = { posts };
