---
title: "My New Blog Home with Azure Static Web App"
slug: my-new-blog-home
description: >-
  Looking for a new home for my blog posts
added: 2021-01-05T15:57:04+02:00
tags:
  - azure
  - static-web
---
So, I have spent the last few days / weeks deciding the best way to host a blog. Now I have a decidedly "split personality". By this I mean I like to segregate my work and personal hobbies. This can be quite beneficial as this allows me to test a few things.

### A few key decisions

1. Must be version controlled - good practice and forces me to get more familiar with [git](https://git-scm.com/).
2. Must be reliable and redundant, or at least enough to re-deploy if needed - see point 1 :) .
3. Must be as cheap as possible to run and be fairly quick.
4. Must be a learning experience.

Points **1** and **2** makes [git](https://git-scm.com/) a natural choice. Point **3** makes [Azure](https://azure.microsoft.com/en-us/) or [GitHub Pages](https://pages.github.com/) a natural choice. For point **4**, With this being my *"work persona"* I chose Azure Static Web App. I have used GitHub Pages for my *"personal persona"*.

So now with the basics out of the way,  I needed to chose a static content generator. Based on discussions with a few people and again wanting to learn something, [hugo](https://gohugo.io/getting-started/installing/) was chosen and then there is a great guide [here](https://docs.microsoft.com/en-us/azure/static-web-apps/publish-hugo) as a starting point.

The blog you are reading now is hosted with the above criteria and of course a custom domain name.

More to come soon.


