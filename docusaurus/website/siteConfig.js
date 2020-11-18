/**
 * Copyright (c) 2017-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// See https://docusaurus.io/docs/site-config for all the possible
// site configuration options.

// List of projects/orgs using your project for the users page.
// const users = [
//   {
//     caption: 'User1',
//     // You will need to prepend the image path with your baseUrl
//     // if it is not '/', like: '/test-site/img/image.jpg'.
//     image: 'https://github.com/sider/goodcheck/raw/master/logo/GoodCheck%20Horizontal.png',
//     infoLink: 'https://github.com/sider/goodcheck',
//     pinned: true,
//   },
// ];

const siteConfig = {
  title: 'Goodcheck', // Title for your website.
  tagline: 'A regexp based customizable linter',
  url: 'https://sider.github.io', // Your website URL
  baseUrl: '/goodcheck/', // Base URL for your project */
  // For github.io type URLs, you would set the url and baseUrl like:
  //   url: 'https://facebook.github.io',
  //   baseUrl: '/test-site/',

  // Used for publishing and more
  projectName: 'goodcheck',
  organizationName: 'sider',
  // For top-level user or org sites, the organization is still the same.
  // e.g., for the https://JoelMarcey.github.io site, it would be set like...
  //   organizationName: 'JoelMarcey'

  // For no header links in the top nav bar -> headerLinks: [],
  headerLinks: [
    { doc: 'getstarted', label: 'Get Started' },
    { doc: 'configuration', label: 'Configuration' },
    { doc: 'commands', label: 'Commands' },
    { doc: 'rules', label: 'Rule' },
  ],

  // If you have users set above, you add it here:
  // users,

  /* path to images for header/footer */
  headerIcon: 'img/favicon.ico',
  footerIcon: 'img/favicon.ico',
  favicon: 'img/favicon.ico',

  /* Colors for website */
  colors: {
    primaryColor: '#09345D', // hsl(209, 82%, 19%)
    secondaryColor: '#044d82',
    lightColor: '#eaeef3',
  },

  /* Custom fonts for website */
  /*
  fonts: {
    myFont: [
      "Times New Roman",
      "Serif"
    ],
    myOtherFont: [
      "-apple-system",
      "system-ui"
    ]
  },
  */

  // This copyright info is used in /core/Footer.js and blog RSS/Atom feeds.
  copyright: `Copyright © ${new Date().getFullYear()} Goodcheck`,

  highlight: {
    // Highlight.js theme to use for syntax highlighting in code blocks.
    theme: 'mono-blue',
  },

  // Add custom scripts here that would be placed in <script> tags.
  scripts: [
    'https://buttons.github.io/buttons.js',
    'https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/2.0.0/clipboard.min.js',
    '/js/code-block-buttons.js',
  ],
  stylesheets: ['/css/code-block-buttons.css'],

  // On page navigation for the current documentation page.
  onPageNav: 'separate',
  // No .html extensions for paths.
  cleanUrl: true,

  // Open Graph and Twitter card images.
  // ogImage: 'img/undraw_online.svg',
  // twitterImage: 'img/undraw_tweetstorm.svg',

  // For sites with a sizable amount of content, set collapsible to true.
  // Expand/collapse the links and subcategories under categories.
  // docsSideNavCollapsible: true,

  // Show documentation's last contributor's name.
  // enableUpdateBy: true,

  // Show documentation's last update time.
  // enableUpdateTime: true,

  // You may provide arbitrary config keys to be used as needed by your
  // template. For example, if you need your repo's URL...
  repoUrl: 'https://github.com/sider/goodcheck',

  splash: {
    title: `Goodcheck`,
    description: "A regexp based customizable linter",
    button: "Get Started",
    id: "com.example.github",
    pattern: "Github",
    message: `|
      GitHub is GitHub, not Github

      You may have misspelling the name of the service!`,
    resultFront: `index.html: 91:    - <a>Signup via `,
    match: "Github",
    resultEnd: `</a>:    GitHub is GitHub, not Github`
  },

  featureOne: {
    title: `A Goodcheck rule`,
    description:
      "Define patterns with messages in a goodcheck.yml file and run goodcheck within your repository. Any matching results will be displayed in the terminal.",
    id: "com.sample.no-blink",
    pattern: "<blink",
    message: `|
      Stop using <blink> tag`,

    resultFront: `index.html:50:          <h3>`,
    match: "<blink>",
    resultEnd: `HTML5 Markup</blink></h3>:   Stop using <blink> tag`
  },

  featureTwo: {
    title: `A rule with negated pattern`,
    description:
      "Goodcheck rules are usually to detect if something is included in a file. You can define the negated rules for the opposite, something is missing in a file.",
    id: "com.sample.negated",
    not: true,
    pattern: "<!DOCTYPE html>",
    message: `|
      Write a doctype on HTML files.`,

    resultFront: `index.html:-:<html lang="en">:  Write a doctype on HTML files.`,
    glob: "**/*.html"
  },

  featureThree: {
    title: `A rule without pattern`,
    description:
      "You can define a rule without pattern. The rule emits an issue on each file specified with glob. You cannot omit glob from a rule definition without pattern. ",
    id: "com.sample.without_pattern",
    message: `|
      Read the operation manual for DB migration: https://example.com/guides/123 `,

    resultFront: `db/schema.rb:-:# This file is auto-generated from the current state of the database. Instead: Read the operation manual for DB migration: https://example.com/guides/123`,
    glob: "db/schema.rb"
  },
};

module.exports = siteConfig;
