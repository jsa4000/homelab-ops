<h1 align="center">

# Homelab

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://github.com/jsa4000/homelab-ops/blob/main/LICENSE/ "License")
[![Docs](https://img.shields.io/static/v1.svg?color=009688&labelColor=555555&logoColor=ffffff&label=Homelab&message=Docs&logo=readthedocs)](https://jsa4000.github.io/homelab-ops/ "Documentation for this repository.")
[![GitHub stars](https://img.shields.io/github/stars/jsa4000/homelab-ops?color=green)](https://github.com/jsa4000/homelab-ops/stargazers "This repo star count")
[![GitHub last commit](https://img.shields.io/github/last-commit/jsa4000/homelab-ops?color=purple)](https://github.com/jsa4000/homelab-ops/commits/main "Commit History")
[![OS](https://img.shields.io/badge/Ubuntu-22.04-important&logo=ubuntu)](https://releases.ubuntu.com/22.04/ "Ubuntu 22.04 Jelly")
[![Kubernetes Distribution](https://img.shields.io/badge/Kubernetes-k3s-informational&logo=kubernetes)](https://k3s.io/ "k3s")
[![Release](https://img.shields.io/github/v/release/jsa4000/homelab-ops&logo=semanticrelease)](https://github.com/jsa4000/homelab-ops/releases "Repo releases")
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&logo-pre-commit)](https://github.com/pre-commit/pre-commit "Precommit status")
[![Schedule - Renovate](https://img.shields.io/github/actions/workflow/status/jsa4000/homelab-ops/schedule-renovate.yaml?label=Renovate&logo=renovatebot&branch=main)](https://github.com/Truxnell/home-cluster/actions/workflows/schedule-renovate.yaml)

</h1>

---

## :book:&nbsp; Overview

A repository to create a cluster to be used as homelab.

## :wrench:&nbsp; Tools

Below are some of the tools I find useful.

| Tool                                                            | Purpose                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| [ansible](https://github.com/ansible/ansible)                   | Configuration management tool and simple IT automation system                        |
| [Renovate](https://github.com/renovatebot/renovate)             | Automatically finds new releases for the applications and issues corresponding PR's  |
| [TaskFile](https://github.com/go-task/task)                     | Task runner/build tool that aims to be simpler and easier to use than GNU Make.      |
| [pre-commit](https://github.com/pre-commit/pre-commit)          | A framework for managing and maintaining multi-language pre-commit hooks.            |
| [kubesearch](https://kubesearch.dev/)                           | Look for how other people manage their Self-hosted software on k8s-at-home community |
| [mkdocs material](https://squidfunk.github.io/mkdocs-material/) | Static website generator for all my docs in this repo                                |
| [Age](https://github.com/FiloSottile/age)                       | Simple, modern and secure file encryption tool, format, and Go library.              |
| [yamlfmt](https://github.com/google/yamlfmt)                    | Extensible command line tool or library to format yaml files.                        |
| [prettier](https://github.com/prettier/prettier)                | Opinionated code formatter, that enforces a consistent style                         |
| [markdownlint](https://github.com/DavidAnson/markdownlint)      | Static analysis tool to enforce standards and consistency for Markdown files.        |

### Pre-Commit

Installation can be made using `pip install` or a package manager such as `homebrew`.

```bash
# Install via homebrew
brew install pre-commit
```

Install the `git-hooks` scripts, be sure `.pre-commit-config.yaml` configuration fle has been created in the root folder.

```bash
# Install
pre-commit install
```

Now `pre-commit` will run automatically on `git commit`.

### MkDocs

Installation can be made using `pip install` or a package manager such as `homebrew`.

```bash
# Install via homebrew
brew install mkdocs
```

Initialize a project using `mkdocs`

```bash
# Create a mkdocs project
mkdocs new .
```

Serve the website content on a local server

```bash
mkdocs serve
```

### Renovate

Go to [Renovate](https://github.com/apps/renovate) install the app into the account.

### TaskFile

Task offers many installation methods, so package manager such as `homebrew` can be used.

```bash
# Install via homebrew
brew install go-task
```

Get all current tasks

```bash
# List all available task to run
task -l

# 'task -l' can be set as default task tu run
task
```

Run following task to install dependencies using `homebrew`

```bash
# Run 'init' task within brew include file
task brew:init
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=jsa4000/homelab-ops&type=Date)](https://star-history.com/#jsa4000/homelab-ops&Date)
