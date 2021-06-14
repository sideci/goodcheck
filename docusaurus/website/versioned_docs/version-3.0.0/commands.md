---
id: version-3.0.0-commands
title: Commands
sidebar_label: Commands
original_id: commands
---

## `goodcheck init [options]`

The `init` command generates an example of a configuration file.

Available options are:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file name to generate
* `--force` to allow overwriting of an existing config file

## `goodcheck check [options] targets...`

The `check` command checks your programs under `targets...`.
You can pass directories or files.

When you omit `targets`, it checks all files in `.` (the current directory).

Available options are:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file
* `-R [rule]`, `--rule=[rule]` to specify the rules you want to check
* `--format=[text|json]` to specify output format
* `-v`, `--verbose` to be verbose
* `--debug` to print all debug messages
* `--force` to ignore downloaded caches

You can check its exit status to identify if the tool finds some pattern or not.

## `goodcheck test [options]`

The `test` command tests rules.
The test contains:

* validation of rule `id` uniqueness
* if `pass` examples does not match with any of `pattern`s
* if `fail` examples matches with some of `pattern`s

Use the `test` command when you add a new rule to be sure you are writing rules correctly.

Available options are:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file
* `-v`, `--verbose` to be verbose
* `--debug` to print all debug messages
* `--force` to ignore downloaded caches

## `goodcheck pattern [options] ids...`

The `pattern` command prints the regular expressions generated from the patterns.
The command is for debugging patterns, especially token patterns.

An available option is:

* `-c [CONFIG]`, `--config=[CONFIG]` to specify the configuration file

## `goodcheck help`

The `help` command prints the full help text.

## Exit status

The `goodcheck` command exits with the status:

* `0` when it succeeds or does not find any matching text fragment
* `1` when it encounters an fatal error
* `2` when it finds some matching text
* `3` when it finds some test failure
