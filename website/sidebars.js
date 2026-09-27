/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docsSidebar: [
    'intro',
    'getting-started',
    {
      type: 'category',
      label: 'Core Guides',
      collapsed: false,
      items: ['parsing', 'formatting', 'timezones', 'ranges', 'humanize', 'locales'],
    },
    'api-reference',
    'migration',
    'testing',
    'stability',
  ],
};

module.exports = sidebars;
