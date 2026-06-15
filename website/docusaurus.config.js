// @ts-check

const {themes} = require('prism-react-renderer');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Morrow.mojo',
  tagline: 'Human-friendly date and time utilities for Mojo',
  favicon: 'img/morrow-logo.svg',

  url: 'https://mojoto.github.io',
  baseUrl: '/morrow.mojo/',
  organizationName: 'mojoto',
  projectName: 'morrow.mojo',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/mojoto/morrow.mojo/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/morrow-social-card.svg',
      navbar: {
        title: 'Morrow.mojo',
        logo: {
          alt: 'Morrow.mojo logo',
          src: 'img/morrow-logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'docsSidebar',
            position: 'left',
            label: 'Docs',
          },
          {
            href: 'https://github.com/mojoto/morrow.mojo',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Getting Started',
                to: '/docs/getting-started',
              },
              {
                label: 'API Reference',
                to: '/docs/api-reference',
              },
            ],
          },
          {
            title: 'Project',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/mojoto/morrow.mojo',
              },
              {
                label: 'Releases',
                href: 'https://github.com/mojoto/morrow.mojo/releases',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Morrow.mojo contributors.`,
      },
      prism: {
        theme: themes.github,
        darkTheme: themes.dracula,
      },
    }),
};

module.exports = config;
