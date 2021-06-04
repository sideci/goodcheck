---
id: configuration
title: Configuration
sidebar_label: Configuration
---

## `goodcheck.yml`

The default Goodcheck configuration file is named `goodcheck.yml`.
An example of the configuration is like the following:

```yaml
rules:
  - id: com.example.github
    pattern: Github
    severity: warning
    message: |
      GitHub is GitHub, not Github

      You may misspelling the name of the service!
    justification:
      - When you mean a service different from GitHub
      - When GitHub is renamed
    glob:
      - app/views/**/*.html.slim
      - config/locales/**/*.yml
    pass:
      - <a>Signup via GitHub</a>
    fail:
      - <a>Signup via Github</a>

import:
  - goodcheck/*.yml

exclude:
  - vendor
```

A *rule* hash under the `rules` list contains the following attributes:

| Name                    | Description                                                    | Required? |
| ----------------------- | -------------------------------------------------------------- | --------- |
| `id`                    | A string to identify a rule                                    | yes       |
| `message`               | A message to tell writers why the code piece should be revised | yes       |
| [`pattern`](#pattern)   | A pattern or patterns of text to be scanned                    | no        |
| `justification`         | Messages to tell writers when an exception can be allowed      | no        |
| [`glob`](#glob)         | A glob or globs of files to be scanned                         | no        |
| [`severity`](#severity) | A severity of a rule                                           | no        |
| `pass`                  | A pattern or patterns that do not match this rule              | no        |
| `fail`                  | A pattern or patterns that match this rule                     | no        |

## `pattern`

The `pattern` can be one of either:

- [string literal](#string-literal)
- [*literal pattern*](#literal-pattern)
- [*regexp pattern*](#regexp-pattern)
- [*token pattern*](#token-pattern)

### string literal

A string literal represents a *literal pattern* or *regexp pattern*.

```yaml
pattern:
  - This is a literal pattern
  - /This is a regexp pattern/
  - /This is a regexp pattern with the case-insensitive option/i
  - /This is a regexp pattern with the multiline option/m
```

If the string value begins with `/` and ends with `/`, it is a *regexp pattern*.
You can optionally specify regexp options like `/case-insensitive/i` or `/multiline/m`.

### *literal pattern*

A *literal pattern* allows you to construct a regexp which matches exactly to the `literal` string.

```yaml
id: com.sample.GitHub
pattern:
  literal: Github
  case_sensitive: true
message: Write GitHub, not Github
```

All regexp meta characters included in the `literal` value will be escaped.
`case_sensitive` is an optional attribute and the default is `true`.

### *regexp pattern*

A *regexp pattern* allows you to write a regexp with meta characters.

```yaml
id: com.sample.digits
pattern:
  regexp: \d{4,}
  case_sensitive: false
  multiline: false
message: Insert delimiters when writing large numbers
justification:
  - When you are not writing numbers, including phone numbers, zip code, ...
```

It accepts two optional attributes, `case_sensitive` and `multiline`.
The default values of `case_sensitive` and `multiline` are `true` and `false` respectively.

The regexp will be passed to [`Regexp.compile`](https://ruby-doc.org/core/Regexp.html#compile-method) of Ruby.
The precise definition of regular expressions can be found in the documentation for Ruby.

### *token pattern*

A *token pattern* compiles to a *tokenized* regexp.

```yaml
id: com.sample.no-blink
pattern:
  token: "<blink"
  case_sensitive: false
message: Stop using <blink> tag
glob: "**/*.html"
justification:
  - If Lynx is the major target of the web site
```

It tries to tokenize the input and generates a regexp which matches a sequence of tokens.
The tokenization is heuristic and may not work well for your programming language.
In that case, try using a *regexp pattern*.

The generated regexp of `<blink` is `<\s*blink\b/m`.
It matches with `<blink />` and `< BLINK>`, but does not match with `https://www.chromium.org/blink`.

It accepts one optional attribute `case_sensitive`.
The default value of `case_sensitive` is `true`.
Note that the generated regexp is in multiline mode.

A *token pattern* can have an optional `where` attribute and *variable bindings*.

```yaml
pattern:
  - token: bgcolor=${color:string}
    where:
      color: true
```

The variable binding consists of a *variable name* and a *variable type*, where `color` and `string` in the example above respectively.
You have to add a key of the *variable name* in `where` attribute.

Goodcheck has 8 built-in patterns:

* `string`
* `int`
* `float`
* `number`
* `url`
* `email`
* `word`
* `identifier`

You can find the exact definitions of the types in the definition of `Goodcheck::Pattern::Token` (`@@TYPES`).

You can omit the type of variable binding.

```yaml
pattern:
  - token: "margin-left: ${size}px;"
    where:
      size: true
  - token: "backgroundColor={${color}}"
    where:
      color: true
```

In this case, the following character will be used to detect the range of binding.
In the first example above, the `px` will be used as the marker for the end of `size` binding.

If parens or brackets are surrounding the variable, Goodcheck tries to match with nested ones in the variable.
It expands five levels of nesting. See the example of matches with the second `backgroundColor` pattern:

- `backgroundColor={color}` matches (`color=="color"`)
- `backgroundColor={{ red: red(), green: green(), blue: green()-1 }}` matches (`color=="{ red: red(), green: green(), blue: green()-1 }"`)
- `backgroundColor={ {{{{{{}}}}}} }` matches (`color==" {{{{{{}}}}}"`)

## `glob`

The `glob` can be a string or a hash.

```yaml
glob: "**/test/**/*.rb"

# or
glob:
  pattern: "legacy/**/*.rb"
  encoding: EUC-JP
  exclude: ["**/test/**", "**/spec/**"]

# or
glob:
  - "**/test/**/*.rb"
  - pattern: "legacy/**/*.rb"
    encoding: EUC-JP
    exclude: ["**/test/**", "**/spec/**"]
```

The hash can have an optional `encoding` attribute.
You can specify the encoding of the file by the names defined for Ruby.
The list of all available encoding names can be found by the command:

```console
$ ruby -e "puts Encoding.name_list"
```

The default value is `UTF-8`.

Also, the hash can have an optional `exclude` attribute.
You can exclude any files from the `pattern` matched ones by this attribute.

If you write a string as a `glob`, the string value can be the `pattern` of the glob, without `encoding` attribute.

If you omit the `glob` attribute in a rule, the rule will be applied to all files given to Goodcheck.

If both your rule and its pattern has `glob`, Goodcheck will scan the pattern with files matching the `glob` condition in the pattern.

```yaml
rules:
  - id: glob_test
    pattern:
      - literal: 123      # This pattern applies to .css files
        glob: "*.css"
      - literal: abc      # This pattern applies to .txt files
    glob: "*.txt"
```

## A rule with _negated_ pattern

Goodcheck rules are usually to detect _something is included in a file_.
You can define the _negated_ rules for the opposite, _something is missing in a file_.

```yaml
rules:
  - id: negated
    not:
      pattern: "<!DOCTYPE html>"
    message: Write a doctype on HTML files.
    glob: "**/*.html"
```

## A rule without pattern

You can define a rule without `pattern`.
The rule emits an issue on each file specified with `glob`.
You cannot omit `glob` from a rule definition without `pattern`.

```yaml
rules:
  - id: without_pattern
    message: |
      Read the operation manual for DB migration: https://example.com/guides/123
    glob: db/schema.rb
```

The output will be something like:

```console
$ goodcheck check
db/schema.rb:-:# This file is auto-generated from the current state of the database. Instead: Read the operation manual for DB migration: https://example.com/guides/123
```

## Triggers

The version 2.0.0 introduces a new abstraction to define patterns, called *trigger*.
You can continue using a `pattern` in a `rule`, but using a `trigger` allows more flexible pattern definitions and more precise testing.

```yaml
rules:
  - id: trigger
    message: Using trigger
    trigger:
      - pattern: <blink
        glob: "**/*.html"
        fail:
          - <blink></blink>
      - not:
          pattern:
            token: <meta charset="UTF-8">
            case_sensitive: false
        glob: "**/*.html"
        pass: |
          <html>
            <meta charset="utf-8"></meta>
          </html>
```

You can keep `pattern` definitions, but using `goodcheck test` against `pattern` with `glob` does not work.
If your `pattern` definition includes `glob`, switching to `trigger` would make sense.

## Importing rules

`goodcheck.yml` can have an optional `import` attribute.

```yaml
import:
  - lib/goodcheck/rules.yml
  - lib/goodcheck/rules/**/*.yml
  - file:///usr/share/goodcheck/rules.yml
  - https://some.host/shared/rules.yml
  - https://some.host/shared/rules.tar.gz
```

The value of `import` can be an array of:

- a string or glob pattern which represents a relative file path from the config file such as `goodcheck.yml`
- a file/http/https URL which represents the location of rules
- a file/http/https URL, with a `.tar.gz` extension, which includes rule files

The rules file to be imported should be a YAML file with an array of rules, for example:

```yaml
- id: imported_rule_1
  message: Rule 1
  pattern: rule-1

- id: imported_rule_2
  message: Rule 2
  pattern: rule-2

# more rules...
```

## Downloaded rules

Downloaded rules are cached in the *cache* directory in the *Goodcheck home directory*.
The *Goodcheck home directory* is `~/.goodcheck`, but you can customize the location with `GOODCHECK_HOME` environment variable.

The cache expires in 3 minutes.

## Excluding files

`goodcheck.yml` can have an optional `exclude` or `exclude_binary` attribute, which allows you to exclude any files.

```yaml
exclude:
  - node_modules
  - vendor
  - assets/**/*.png

exclude_binary: true
```

- `exclude` - allows one or more strings, representing an excluded directory or a glob pattern for excluded files.
- `exclude_binary` - allows a boolean. Defaults to `false`. If enabled, Goodcheck will exclude files considered as *binary*.
  For example, files like `foo.png` or `bar.zip` are considered as *binary*.

## Severity

A *severity* expresses an importance level of a rule. Predefined severities are `error` and `warning`.
You can set any severity to a rule, e.g. `info` or `convention`.

If you want to restrict severities available within your configuration, you can the top-level `severity` field. See the example below:

```yaml
rules:
  - id: valid-severity
    pattern: bar
    message: Disallow `bar`
    severity: error         # OK

  - id: invalid-severity
    pattern: foo
    message: Disallow `foo`
    severity: convention    # NG

severity: [error, warning, info]
```

The default list of severities is *empty*, that is, any severities are allowed.

## Disabling rules with inline comments

You can disable rule warnings on a specific line using inline comments supported by common languages.

- `goodcheck-disable-line`
- `goodcheck-disable-next-line`

For example, for Ruby:

```rb
# goodcheck-disable-next-line
puts "Github"
puts "Github" # goodcheck-disable-line
```

For JavaScript:

```js
// goodcheck-disable-next-line
console.log("Github")
console.log("Github") // goodcheck-disable-line
```
