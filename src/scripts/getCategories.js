export default function getCategories(posts) {
	const allCategories = posts
		.map((post) => {
			const postCategories = post.data.categories;
			let categories = [];

			if (postCategories?.length > 0) {
				postCategories.forEach((category) => {
					if (categories?.indexOf(category) === -1) {
						categories.push(category);
					}
				});
			}

			return categories;
		})
		.flat(1);

	return [...new Set(allCategories)];
}