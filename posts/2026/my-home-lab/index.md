---
added:  '2026-07-24T09:57:34+01:00'
title: 'My Home Lab'
tags:
    - 'home-lab'
    - 'unRAID'
    - 'docker'
    - 'self-hosting'
author: 'Fletcher Kelly'
categories:
    - self-hosting
slug: 2026-my-home-lab
description: 'An overview of my home lab setup, the technologies I use, and my approach to self-hosting.'
---

Why do I have a home lab and what do I use it for? This is a question I get asked a lot and I thought I would write a post to explain my home lab and what I use it for. This is not a comprehensive list of everything I use, but it will give you an idea of what I use and why.

<!--more-->
> **NB:** These are my personal thoughts and are in no way associated with my employer or work profile.

Let's get some of the basics out of the way quickly.

**Do I self-host everything?** No, I do not. I self-host some things, but not everything. I use a combination of self-hosted and cloud-based services to meet my needs. I use self-hosting for things that I want to have more control over, and I use cloud-based services for things that I want to have more convenience and flexibility.

**Do I use cloud services?** Yes, there are some aspects of these technologies that I do not want to self-host, or create a full "mission critical dependency" on my self hosted lab. There is a time and place for everything.

**Do I have some subscription services?** Yes, of course. I have however made a choice and understood the cost/value/benefit of these services.

This post and my self-hosting is part of my learning toolbox and is one of many tools that I use to learn and understand the concepts of automation, scripting, containers, virtualization, and self-hosting. I have been using these technologies for a long time and have learned a lot from them. I have also learned a lot from the community and from other people who have shared their experiences and knowledge.

I have been having discussions around which tools and technologies to use, I will go into some detail as to what works for me and what I am using. This may not work for you or fit your needs. This is not a problem, if this does not work for you, you can use the concepts.

Concepts:

**Containers, Virtualization, Storage, Networking, Monitoring.**

Technologies **I** use.

- Operating System  

  - I use [unRAID](https://unraid.net/) and I have done so for a long time as it is very lightweight and very forgiving especially in terms of storage. I **REALLY** like that it allows to mix and match hard drives, so it makes concepts like striping and raid configuration almost null and void as it uses its own concept of parity and storage. That is where the name comes from - [unRAID](https://unraid.net/) - it is not a RAID system, it is a storage system that allows you to use different drives and sizes and still have parity and redundancy.

- Docker  

  - I use [Docker](https://www.docker.com/) for containers and specifically the community applications for [unRAID](https://unraid.net/). It still uses all the docker concepts that are almost click to deploy ready containers so you can dive into self-hosting very quickly. As it has been built on top of docker - you can use docker-compose as well if something does not quite fit or if you want to dive deeper into the technologies. For me, this is a great fit, many of the dockers I use are in the community apps in [unRAID](https://unraid.net/) and if they are not, most of these have example docker-compose files that you can use to deploy them.

- Virtualization  

  - [QEMU](https://www.qemu.org/) is the virtualization engine used by [unRAID](https://unraid.net/) and works exactly as I need it to. Is this the only virtualization engine, of course not. I use other virtualization engines in my day to day work, but for my home lab, this is a great fit. It allows me to run virtual machines and containers on the same host and manage them easily as part of my **self-hosted** lab. I can run Windows, Linux, and other operating systems in virtual machines and containers, which is great for testing and learning.

- Storage  

  - I use a combination of local storage and network-attached storage (NAS) for my home lab. [unRAID](https://unraid.net/) allows me to use different drives and sizes and still have parity and redundancy, which is great for my needs. There are some considerations with drive sizes especially with the **parity** drive, it needs to be the biggest drive in your array. If you are are looking to upgrade hard drive sizes in your array, for the first round of upgrades, you will need to upgrade the parity drive first and then you can upgrade the others, this may be seen as a "*double-cost*". Just something to be aware of.

- Networking  

  - I use a combination of wired and wireless networking for my home lab. I have a wired connection to my home lab server, which is great for speed and reliability. I also have a wireless connection for my other devices, which is great for convenience and flexibility. I use VLANs to segment my network and isolate my home lab from my main network, which is great for security and management. I use PoE for many of my devices. I use UNIFI for my wireless access points, I have used these for years and still have an AP that I purchased many years ago. UNIFI makes a point of releasing firmware to ensure these devices are up to date. I use my own firewall, **I DO NOT BELIEVE IN RENTING A ROUTER FROM MY ISP.** This is NOT SECURITY. Your ISP does not have the responsibility of securing your connection, their responsibility is to connect you. Protecting yourself online might be a joint responsibility between you and your ISP, but the responsibility is yours. Do some research and decide which vendor / project works best for you. I am currently using a UNIFI Cloud Gateway. I change (vendors if need be) and upgrade these as needed to meet my needs.  
  - I actively use [Tailscale](https://tailscale.com/), this is a great technology that can be used in many ways to fit your needs. This would be a long post and I would not do this technology justice. Alex Kretzschmar from the now ended Self-Hosted Show now actually works for Tailscale and creates great content on [YouTube](https://www.youtube.com/c/Tailscale) which you can look into to understand how revolutionary this technology actually is. I use this to connect to my home lab from anywhere in the world, and it is great for remote access and management. I use this to connect to my home lab from my mobile devices, which is great for convenience and flexibility.  

- Monitoring

  - I use whatever works for me in the situation as well as some pre-canned open source tooling. For example for [Home Assistant](https://www.home-assistant.io/) I use the built-in monitoring and logging, for my [unRAID](https://unraid.net/) server I use the [NAS Doctor](https://github.com/mcdays94/nas-doctor) and for other pieces in my home lab I am changing all the time what works for me and constantly experimenting. This is the exact point of a home lab. Playing, learning and experimenting with different technologies and tools to see what works best for you and your needs. I use monitoring to ensure that my home lab is running smoothly and to identify any issues that may arise. I also use monitoring to track the performance of my home lab and to make improvements as needed. As long as you have the data you can try different tooling. Remember back in the real world, you will not have the luxury of trying different tooling, you will have to use what is available to you. This is a great way to learn and understand the concepts of monitoring and logging.  

    