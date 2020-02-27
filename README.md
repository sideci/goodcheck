![Goodcheck logo](logo/GoodCheck%20Horizontal.png)

# Goodcheck - Regexp based customizable linter

Are you reviewing a pull request if the change contains deprecated API calls?
Do you want to post a comment to ask the developer if a method call satisfies some condition for use without causing an issue?
What if a misspelling like `Github` for `GitHub` can be found automatically?

Give Goodcheck a try to do them instead of you! 🎉

Goodcheck is a customizable linter. You can define pairs of patterns and messages.
It checks your program and when it detects a piece of text matching with the defined patterns, it prints your message which tells your teammates why it should be revised and how.
Some part of the code reviewing process can be automated.
With Goodcheck the only thing you have to do is define the rules, pairing patterns with messages, and then those same patterns won’t bother you anymore. 😆

## Table of contents

- [Installation](#installation)
- [Quickstart](#quickstart)
- [Defining rules](#defining-rules)
  - [Pattern](#pattern)
  - [Glob](#glob)
  - [A rule with _negated_ pattern](#a-rule-with-negated-pattern)
  - [A rule without pattern](#a-rule-without-pattern)
  - [Triggers](#triggers)
- [Importing rules](#importing-rules)
- [Excluding files](#excluding-files)
- [Commands](#commands)
- [Downloaded rules](#downloaded-rules)
- [Disabling rules with inline comments](#disabling-rules-with-inline-comments)
- [Docker images](#docker-images)
- [Development](#development)
- [Contributing](#contributing)

## Installation

```shell-session
$ gem install goodcheck
```

Or you can use [`bundler`](https://bundler.io)!

If you would not like to install Goodcheck to system (e.g. you would not like to install Ruby 2.4 or higher), you can use a [Docker image](#docker-images).

## Quickstart

```shell-session
$ goodcheck init
$ vim goodcheck.yml
$ goodcheck check
```

The `init` command generates a template of `goodcheck.yml` configuration file for you.
Edit the config file to define patterns you want to check.
Then run `check` command, and it will print matched texts.

### Cheatsheet

You can download a [printable cheatsheet](cheatsheet.pdf) from this repository.

## Defining rules

A `goodcheck.yml` example of the configuration is like the following:

```yaml
rules:
  - id: com.example.github
    pattern: Github
    message: |
      GitHub is GitHub, not Github

      You may be misspelling the name of the service!
    justification:
      - When you mean a service different from GitHub
      - When GitHub is renamed
    glob:
      - app/views/**/*.html.slim
      - config/locales/**/*.yaml
    pass:
      - <a>Signup via GitHub</a>
    fail:
      - <a>Signup via Github</a>
```

A *rule* hash under a `rules` list contains the following keys:

* `id` - a string to identify rules (required)
* [`pattern`](#pattern) - a *pattern* or a sequence of *pattern*s (optional)
* `message` - a string to tell writers why the code piece should be revised (required)
* `justification` - a sequence of strings to tell writers when an exception can be allowed (optional)
* [`glob`](#glob) - a *glob* or a sequence of *glob*s (optional)
* `pass` - a string or a sequence of strings, which does not match the given pattern (optional)
* `fail` - a string or a sequence of strings, which does match the given pattern (optional)

### Pattern

A pattern can be a *literal pattern*, *regexp pattern*, *token pattern*, or a string.

#### String literal

A string literal represents a *literal pattern* or *regexp pattern*.

```yaml
pattern:
  - This is a literal pattern
  - /This is a regexp pattern/
  - /This is a regexp pattern with the casefold option/i
  - /This is a regexp pattern with the multiline option/m
```

If a string value begins with `/` and ends with `/`, it is a *regexp pattern*.
You can optionally specify regexp options like `/casefold/i` or `/multiline/m`.

#### Literal pattern

A *literal pattern* allows you to construct a regexp which matches exactly to the `literal` string.

```yaml
id: com.sample.GitHub
pattern:
  literal: Github
  case_sensitive: true
message: Write GitHub, not Github
```

All regexp meta characters included in the `literal` value will be escaped.
`case_sensitive` is an optional key and the default is `true`.

#### Regexp pattern

A *regexp pattern* allows you to write a regexp with meta chars.

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

The regexp will be passed to [`Regexp.compile`](https://ruby-doc.org/core-2.7.0/Regexp.html#method-c-compile).
The precise definition of regular expressions can be found in the documentation for Ruby.

#### Token pattern

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
In that case, try using *regexp pattern*.

The generated regexp of `<blink` is `<\s*blink\b/m`.
It matches with `<blink />` and `< BLINK>`, but does not match with `https://www.chromium.org/blink`.

It accepts one optional attribute `case_sensitive`.
The default value of `case_sensitive` is `true`.
Note that the generated regexp is in multiline mode.

Token patterns can have an optional `where` attribute and *variable bindings*.

```yaml
pattern:
  - token: bgcolor=${color:string}
    where:
      color: true
```

The variable binding consists of a *name* and *type* (`${name:type}`), where `color` and `string` in the example above respectively. You have to add a key of the variable *name* in `where` attribute.

We have 8 built-in types:

* `string`
* `int`
* `float`
* `number`
* `url`
* `email`
* `word`
* `identifier`

You can find the exact definitions of the types in the definition of [`Goodcheck::Pattern::Token`](lib/goodcheck/pattern.rb) (`@@TYPES`).

You can omit the type of variable binding.

```yaml
pattern:
  - token: margin-left: ${size}px;
    where:
      size: true
  - token: backgroundColor={${color}}
    where:
      color: true
```

In this case, the following character will be used to detect the range of binding. In the first example above, the `px` will be used as the marker for the end of `size` binding.

If parens or brackets are surrounding the variable, Goodcheck tries to match with nested ones in the variable. It expands five levels of nesting. See the example of matches with the second `backgroundColor` pattern:

- `backgroundColor={color}` Matches (`color=="color"`)
- `backgroundColor={{ red: red(), green: green(), blue: green()-1 }}` Matches (`color=="{ red: red(), green: green(), blue: green()-1 }"`)
- `backgroundColor={ {{{{{{}}}}}} }` Matches (`color==" {{{{{{}}}}}"`)

### Glob

A *glob* can be a string or a hash.

```yaml
glob: "**/test/**/*.rb"
# or
glob:
  pattern: "legacy/**/*.rb"
  encoding: EUC-JP
# or
glob:
  - "**/test/**/*.rb"
  - pattern: "legacy/**/*.rb"
    encoding: EUC-JP
```

The hash can have an optional `encoding` attribute.
You can specify the encoding of the file by the names defined for Ruby.
The list of all available encoding names can be found by `$ ruby -e "puts Encoding.name_list"`.
The default value is `UTF-8`.

If you write a string as a `glob`, the string value can be the `pattern` of the glob, without `encoding` attribute.

If you omit the `glob` attribute in a rule, the rule will be applied to all files given to `goodcheck`.

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

### A rule with _negated_ pattern

Goodcheck rules are usually to detect _something is included in a file_.
You can define the _negated_ rules for the opposite, _something is missing in a file_.

```yaml
rules:
  - id: negated
    not:
      pattern:
        <!DOCTYPE html>
    message: Write a doctype on HTML files.
    glob: "**/*.html"
```

### A rule without pattern

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

```shell-session
$ goodcheck check
db/schema.rb:-:# This file is auto-generated from the current state of the database. Instead: Read the operation manual for DB migration: https://example.com/guides/123
```

### Triggers

Version 2.0.0 introduces a new abstraction to define patterns, called *trigger*.
You can continue using `pattern`s in *rule*, but using `trigger` allows more flexible pattern definition and more precise testing.

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

You can continue existing `pattern` definitions, but using `goodcheck test` against `pattern`s with `glob` does not work.
If your `pattern` definition includes `glob`, switching to `trigger` would make sense.

## Importing rules

`goodcheck.yml` can have an optional `import` attribute.

```yaml
import:
  - /usr/share/goodcheck/rules.yml
  - lib/goodcheck/rules.yml
  - https://some.host/shared/rules.yml
```

The value of `import` can be a sequence of:

- A string which represents an absolute file path,
- A string which represents a relative file path from the config file, or
- A http/https URL which represents the location of rules.

The rules file is a YAML file with an sequence of rules:

```yaml
- id: rule1
  pattern: Some pattern 1
  message: Some message 1

- id: rule2
  pattern: Some pattern 2
  message: Some message 2

# ...
```

## Excluding files

`goodcheck.yml` can have an optional `exclude` attribute.

```yaml
exclude:
  - node_modules
  - vendor
  - **/test/**/*.txt
```

The value of `exclude` can be a string or a sequence of strings representing the glob pattern for excluded files.

## Commands

### `goodcheck init [options]`

The `init` command generates an example of a configuration file.

Available options are:

* `-c=[CONFIG]`, `--config=[CONFIG]` to specify the configuration file name to generate.
* `--force` to allow overwriting of an existing config file.

### `goodcheck check [options] targets...`

The `check` command checks your programs under `targets...`.
You can pass:

* Directory paths, or
* Paths to files.

When you omit `targets`, it checks all files in `.` (the current directory).

Available options are:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.
* `-R [rule]`, `--rule=[rule]` to specify the rules you want to check.
* `--format=[text|json]` to specify output format.
* `-v`, `--verbose` to be verbose.
* `--debug` to print all debug messages.
* `--force` to ignore downloaded caches.

`goodcheck check` exits with:

* `0` when it does not find any matching text fragment.
* `2` when it finds some matching text.
* `1` when it finds some error.

You can check its exit status to identify if the tool finds some pattern or not.

### `goodcheck test [options]`

The `test` command tests rules.
The test contains:

* Validation of rule `id` uniqueness.
* If `pass` examples does not match with any of `pattern`s.
* If `fail` examples matches with some of `pattern`s.

Use `test` command when you add a new rule to be sure you are writing rules correctly.

Available options are:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.
* `-v`, `--verbose` to be verbose.
* `--debug` to print all debug messages.
* `--force` to ignore downloaded caches.

### `goodcheck pattern [options] ids...`

The `pattern` command prints the regular expressions generated from the patterns.
The command is for debugging patterns, especially token patterns.

The available option is:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.

## Downloaded rules

Downloaded rules are cached in `cache` directory in *goodcheck home directory*.
The *goodcheck home directory* is `~/.goodcheck`, but you can customize the location with `GOODCHECK_HOME` environment variable.

The cache expires in 3 minutes.

## Disabling rules with inline comments

You can disable rule warnings on a specific line using line comments supported by common languages.

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

## Docker images

We provide Docker images of Goodcheck on [Docker Hub](https://hub.docker.com/r/sider/goodcheck) so that you can try Goodcheck without installing them.

```bash
$ docker pull sider/goodcheck
$ docker run -t --rm -v "$(pwd):/work" sider/goodcheck check
```

The default `latest` tag points to the latest release of Goodcheck.
You can pick a version of Goodcheck from the [Docker Hub tags page](https://hub.docker.com/r/sider/goodcheck/tags).

## Development

After checking out the repository, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, follows the steps below:

1. Update the version number in [`version.rb`](lib/goodcheck/version.rb).
2. Add the new version's entry to the [changelog](CHANGELOG.md).
3. Update the documentation via `bundle exec rake docs:update_version`.
4. Commit the above changes like `git commit -m 'Version 1.2.3'`.
5. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
6. Publish the updated documentation like `GIT_USER=some_user USE_SSH=true bundle exec rake docs:publish`.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/sider/goodcheck).
