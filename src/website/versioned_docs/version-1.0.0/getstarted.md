---
id: version-1.0.0-getstarted
title: Getting Started
sidebar_label: Get Started
original_id: getstarted
---

## Installation

```bash
$ gem install goodcheck
```

Or you can use `bundler`!

If you would not like to install Goodcheck to system (e.g. you would not like to install Ruby 2.4 or higher), you can use a docker image. [See below](#docker-images).

## Docker Images

We provide Docker images of Goodcheck so that you can try Goodcheck without installing them.

- https://hub.docker.com/r/sider/goodcheck/

```bash
$ docker pull sider/goodcheck
$ docker run -t --rm -v "$(pwd):/work" sider/goodcheck check
```

The default `latest` tag points to the latest release of Goodcheck.
You can pick a version of Goodcheck from [tags page](https://hub.docker.com/r/sider/goodcheck/tags).

## Quickstart

```bash
$ goodcheck init
$ vim goodcheck.yml
$ goodcheck check
```

The `init` command generates a template of `goodcheck.yml` configuration file for you.
Edit the config file to define patterns you want to check.
Then run `check` command, and it will print matched texts.





