# WP Plugin Version Guard

<p>
  <a href="https://github.com/gunjanjaswal/WP-Plugin-Version-Guard/actions/workflows/test.yml"><img src="https://github.com/gunjanjaswal/WP-Plugin-Version-Guard/actions/workflows/test.yml/badge.svg" alt="Test"></a>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT">
  <img src="https://img.shields.io/badge/GitHub-Action-2088FF?logo=githubactions&logoColor=white" alt="GitHub Action">
</p>

A tiny GitHub Action that fails your build when a WordPress plugin's version is out of sync across the places it has to match:

- the `Version:` header in the main plugin file
- the `Stable tag:` in `readme.txt`
- a PHP version constant (optional)
- the latest `CHANGELOG.md` heading (optional)

Forget to bump one of them and a release ships with a mismatch that WordPress.org rejects or, worse, that silently stops update notifications. This catches it in CI before it ever gets tagged.

No server, no dependencies. It runs on GitHub's own runners.

## Usage

```yaml
name: Version guard
on: [push, pull_request]

jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gunjanjaswal/WP-Plugin-Version-Guard@v1
        with:
          plugin-file: my-plugin.php
          readme: readme.txt
          constant: MYPLUGIN_VERSION
          changelog: CHANGELOG.md
```

The minimal version, header against `readme.txt` only:

```yaml
      - uses: gunjanjaswal/WP-Plugin-Version-Guard@v1
        with:
          plugin-file: my-plugin.php
```

## Inputs

| Input | Required | Default | What it checks |
| --- | --- | --- | --- |
| `plugin-file` | yes | — | The main plugin file's `Version:` header. This is the reference every other source is compared against. |
| `readme` | no | `readme.txt` | The `Stable tag`. Set to empty to skip. |
| `constant` | no | _(none)_ | A `define('NAME', 'x.y.z')` version constant, searched in the plugin file and, failing that, across the repo. |
| `changelog` | no | _(none)_ | The most recent `## [x.y.z]` heading in a Keep a Changelog file. |

## What it looks like

On a mismatch the step fails and annotates the exact source that is wrong:

```
::error::readme Stable tag (readme.txt) is '1.1.0' but expected '1.2.0' (from the plugin header).
```

It also writes a small table to the workflow summary showing every source and whether it matched.

## License

MIT. See [LICENSE](LICENSE).

## Author

Built by [Gunjan Jaswal](https://www.gunjanjaswal.me). If it saves you a botched release, [buy me a coffee](https://ko-fi.com/gunjanjaswal).
