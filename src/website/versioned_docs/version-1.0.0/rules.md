---
id: version-1.0.0-rules
title: Rules List
sidebar_label: Rules List
original_id: rules
---

Check the [rules list](https://docusaurus.io) for more examples of goodcheck rules.


## Rule: "_blank" Security Issue
When `target = "_blank"` is used, the opened page can access the original window object and potentially redirect the original page to a malicious URL. In this example, the rule will look for patterns of `"_blank"` and suggest to use `rel="noopener"` to prevent the opened page from having access.

```yaml
rules:
  - id: security.link
    pattern:
      - token: 'target="_blank"'
      - token: 'target: "_blank"'
    message: |
      Specify rel="noopener" for security reasons.

      Opening new tab without rel="noopener" may cause a security issue.
      It allows modifying original tab URLs from opened tabs.
    justification:
      - When opening a URL in our service
    glob:
      - "**/*.html"
      - "**/*.html.erb"
    fail:
      - '<a href="https://github.com" target="_blank">GitHub</a>'
    pass:
      - '<a href="/signup">Signup</a>'
```

## Rule: Sign in
> Warning: This rule needs customization.

Keep wording consistent to provide a clear experience for users. In this example, the use of Log in or Log out would prompt the use of sign in / sign out instead.

```yaml
rules:
  - id: wording.signin
    pattern:
      - token: Log in
        case_sensitive: false
      - token: Log out
        case_sensitive: false
    glob:
      - "**/*.html.erb"
      - "**/*.yml"
    message: |
      Please use “sign in”/“sign out”

      We use “sign in” instead of “log in” and “sign out” instead of “log out”.
      See the wording policy for details.

      https://docs.example.com/1840
    fail:
      - "Log in"
      - "Log out"
    pass:
      - "Sign in"
      - "Sign out"
```

## Rule: mixin
> Warning: This rule needs customization.

A mixin lets you make groups of CSS declarations that you want to reuse throughout your site. In this example, it creates a warning when the color pattern is used and suggests using a mixin instead.

```yaml
rules:
  - id: use-mixin
    message: Use mixin.
    pattern: "color: #038cf4;"
    pass:
      - "@include some-mixin;"
    fail:
      - "color: #038cf4;"
```