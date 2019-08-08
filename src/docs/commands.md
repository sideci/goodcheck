---
id: commands
title: Commands
sidebar_label: Commands
---


## `goodcheck init [options]`

The `init` command generates an example of a configuration file.

Available options are:

* `-c=[CONFIG]`, `--config=[CONFIG]` to specify the configuration file name to generate.
* `--force` to allow overwriting of an existing config file.

## `goodcheck check [options] targets...`

The `check` command checks your programs under `targets...`.
You can pass:

* Directory paths, or
* Paths to files.

When you omit `targets`, it checks all files in `.`.

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

## `goodcheck test [options]`

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
* `--force` to ignore downloaded caches

## `goodcheck pattern [options] ids...`

The `pattern` command prints the regular expressions generated from the patterns.
The command is for debugging patterns, especially token patterns.

The available option is:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file.