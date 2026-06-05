// Re-index trigger
import { defineConfig } from "tinacms";

// Your hosting provider likely exposes this as an environment variable
const branch = process.env.HEAD || "main";

export default defineConfig({
	branch,
	clientId: process.env.TINACLIENTID, // Get this from tina.io
	token: process.env.TINATOKEN, // Get this from tina.io

	build: {
		outputFolder: "admin",
		publicFolder: "public",
		basePath: "blog",
	},
	media: {
		tina: {
			mediaRoot: "assets",
			publicFolder: "public",
		},
	},
	schema: {
		collections: [
			{
				label: "Site Settings",
				name: "settings",
				path: "src/settings",
				format: "json",
				fields: [
					{
						type: "string",
						label: "Site Title",
						name: "title",
					},
					{
						type: "string",
						label: "Site subtitle",
						name: "subtitle",
					},
				],
				ui: {
					allowedActions: {
						create: false,
						delete: false,
					},
				},
			},
			{
				name: "post",
				label: "Posts",
				path: "posts",
				defaultItem: () => ({
					title: "New Post",
					added: new Date(),
					tags: [],
					categories: [],
				}),
				ui: {
					dateFormat: "MMM DD YYYY",
					filename: {
						readonly: false,
						slugify: (values) => {
							return values?.slug?.toLowerCase().replace(/ /g, "-");
						},
					},
				},
				fields: [
					{
						name: "title",
						label: "Title",
						type: "string",
						isTitle: true,
						required: true,
					},
					{
						label: "Slug",
						name: "slug",
						type: "string",
						required: true,
					},
					{
						label: "Description",
						name: "description",
						type: "string",
						required: true,
					},
					{
						label: "Tags",
						name: "tags",
						type: "string",
						list: true,
						options: [
							{ value: "technical", label: "Technical" },
							{ value: "advice", label: "Advice" },
							{ value: "events", label: "Events" },
							{ value: "learning", label: "Learning" },
							{ value: "meta", label: "Meta" },
							{ value: "work", label: "Work" },
							{ value: "personal", label: "Personal" },
							{ value: "projects", label: "Projects" },
							{ value: "azure", label: "Azure" },
							{ value: "avs", label: "AVS" },
							{ value: "bicep", label: "Bicep" },
							{ value: "powershell", label: "PowerShell" },
							{ value: "ssh", label: "SSH" },
							{ value: "ssh-keys", label: "SSH Keys" },
							{ value: "networking", label: "Networking" },
							{ value: "iac", label: "IaC" },
							{ value: "cdn", label: "CDN" },
							{ value: "rest-api", label: "REST API" },
							{ value: "postman", label: "Postman" },
							{ value: "csa", label: "CSA" },
							{ value: "cloud-tools", label: "Cloud Tools" },
							{ value: "hugo", label: "Hugo" },
							{ value: "blog", label: "Blog" },
							{ value: "key-vault", label: "Key Vault" },
							{ value: "cost-management", label: "Cost Management" },
							{ value: "ldaps", label: "LDAPS" },
							{ value: "vmware", label: "VMware" },
							{ value: "arc", label: "Arc" },
							{ value: "arg", label: "Azure Resource Graph" },
							{ value: "container", label: "Container" },
							{ value: "storage", label: "Storage" },
							{ value: "monitoring", label: "Monitoring" },
							{ value: "automation", label: "Automation" },
							{ value: "devops", label: "DevOps" },
						],
					},
					{
						label: "Categories",
						name: "categories",
						type: "string",
						list: true,
						options: [
							{ value: "home-automation", label: "Home Automation" },
							{ value: "software", label: "Software" },
							{ value: "projects", label: "Projects" },
							{ value: "personal", label: "Personal" },
							{ value: "cloud", label: "Cloud" },
							{ value: "azure", label: "Azure" },
							{ value: "iac", label: "IaC" },
							{ value: "networking", label: "Networking" },
							{ value: "devops", label: "DevOps" },
							{ value: "vmware", label: "VMware" },
							{ value: "infrastructure", label: "Infrastructure" },
						],
					},
					{
						label: "Added",
						name: "added",
						type: "datetime",
						dateFormat: "MMM DD YYYY",
						required: true,
					},
					{
						label: "Updated",
						name: "updated",
						type: "datetime",
						dateFormat: "MMM DD YYYY",
					},
					{
						type: "rich-text",
						name: "body",
						label: "Body",
						isBody: true,
					},
				],
			},
		],
	},
	search: {
		tina: {
			indexerToken: process.env.TINASEARCH,
			stopwordLanguages: ["eng"],
		},
		indexBatchSize: 50,
		maxSearchIndexFieldLength: 100,
	},
});

