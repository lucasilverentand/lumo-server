// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightThemeRapide from 'starlight-theme-rapide';

// https://astro.build/config
export default defineConfig({
	site: 'https://lucasilverentand.github.io',
	base: '/lumo-server',
	integrations: [
		starlight({
			plugins: [starlightThemeRapide()],
			title: 'Lumo Server',
			description: 'Docker-based Minecraft Paper server with 20+ plugins and autopause',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/lucasilverentand/lumo-server' },
			],
			sidebar: [
				{
					label: 'Getting Started',
					items: [
						{ label: 'Introduction', slug: 'index' },
						{ label: 'Quick Start', slug: 'getting-started/quick-start' },
						{ label: 'Docker Setup', slug: 'getting-started/docker' },
					],
				},
				{
					label: 'Deployment',
					items: [
						{ label: 'Kubernetes', slug: 'deployment/kubernetes' },
						{ label: 'Docker Compose', slug: 'deployment/docker-compose' },
					],
				},
				{
					label: 'Configuration',
					items: [
						{ label: 'Environment Variables', slug: 'configuration/environment' },
						{ label: 'Server Properties', slug: 'configuration/server-properties' },
						{ label: 'Plugin Configuration', slug: 'configuration/plugins' },
					],
				},
				{
					label: 'Features',
					items: [
						{ label: 'Automated Backups', slug: 'features/backups' },
						{ label: 'Autopause', slug: 'features/autopause' },
						{ label: 'World Management', slug: 'features/worlds' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'Architecture', slug: 'reference/architecture' },
						{ label: 'Plugins List', slug: 'reference/plugins' },
						{ label: 'Troubleshooting', slug: 'reference/troubleshooting' },
					],
				},
			],
		}),
	],
});
