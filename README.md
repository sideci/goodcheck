# goodcheck
Regexp based customizable linter

To edit this website fork the repo and edit the files in the src directory.

## Notes
The example code on the index page could be changed in the siteConfig.js file. It only accepts information for basic rules. If you would like to edit this you can look at the `FeatureCodeBoxExtended` in the index.js file. Another option would be to use highlight.js, though I couldn't get it to work without the styles conflicting with the code in the other pages.

## Deploy the site
Once you've made your edits run
`$ GIT_USER=<GIT_USER> CURRENT_BRANCH=master yarn run publish-gh-pages`

If you need help refer to the [Docusarus Documentation](https://docusaurus.io/docs/en/publishing)
