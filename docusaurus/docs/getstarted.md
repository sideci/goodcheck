---
id: getstarted
title: Getting Started
sidebar_label: Get Started
---

## Installation

```console
$ gem install goodcheck
```

Or you can use [`bundler`](https://bundler.io):

```console
$ bundle add goodcheck
```

If you would not like to install Goodcheck to system (e.g. you would not like to install Ruby), you can use our [Docker images](#docker-images).

## Docker images

We provide the Docker images for Goodcheck so that you can try Goodcheck without installing it to your system.
Visit our [Docker Hub](https://hub.docker.com/r/sider/goodcheck/) page for more details.

For example:

```console
$ docker run -t --rm -v "$(pwd):/work" sider/goodcheck check
```

The default `latest` tag points to the latest version of Goodcheck.
You can pick any version of Goodcheck from the [released tags](https://hub.docker.com/r/sider/goodcheck/tags).

## Quickstart

```console
$ goodcheck init
$ vim goodcheck.yml
$ goodcheck check
```

The `init` command generates a template of `goodcheck.yml` configuration file for you.
Edit the config file to define patterns you want to check.
Then run `check` command, and it will print matched texts.

## Cheatsheet

You can download a [printable cheatsheet](https://github.com/sider/goodcheck/blob/master/cheatsheet.pdf) from this repository.
