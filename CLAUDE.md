# go-utils-depot

Public binary distribution repo for Go CLI tools.

## Adding a new tool

Each tool gets its own folder with docs:

```
<tool>/
├── README.md               # What it is, when to use it, install, quick start
├── CHANGELOG.md             # Keep a Changelog format
└── docs/
    ├── SKILL.md             # Full usage guide (all commands, workflows, examples)
    └── <other>.md           # Additional reference docs as needed
```

Steps:

1. Create `<tool>/README.md` and `<tool>/docs/SKILL.md` (copy from source, fix install line to use eget)
2. Add the tool to the table in README.md
3. Commit and push

## Releasing a version

Binaries are cross-compiled locally and uploaded via `gh`:

```bash
./scripts/release.sh <source-dir> <tool> <version>

# Examples
./scripts/release.sh ../path-to-source/sotto sotto v0.2.0
./scripts/release.sh ../path-to-source/notion notion v0.1.0
./scripts/release.sh ../path-to-source/logfire-trace logfire-trace v0.6.0
```

Builds static binaries for each tool's supported platforms, packages them, generates checksums, and creates a GitHub release tagged `<tool>/<version>`. `lightdashctl` and `dbexplorer` currently ship macOS and Linux binaries only because their source modules use Unix file locking.

Requires `go` and `gh` authenticated with release permission for this repository.
To use the two-argument form, set `RELEASE_SOURCE_ROOT=/path/to/sources`
or save the source root path in `.release-source-root` (ignored by Git).
Registered tools are subdirectories of that root. Without a configured root,
the script looks for a sibling checkout named after the tool. The explicit
three-argument form always takes precedence. Keep machine-specific paths out
of committed scripts and documentation.
For local verification before publication, set `RELEASE_BUILD_ONLY=1`; this
builds archives and checksums under `dist/` without creating a GitHub release.

Revlet archives include companion runtime files. `scripts/package-revlet.py`
stages the pinned browser helper, dependencies, licenses, public docs, and skill.
Live mode requires extracting the full archive with `browser/` beside the binary;
eget's binary-only install supports annotation, file review, and snapshots.
Revlet packaging also requires Python 3.

## Important

This is a public repo. Never commit source code, secrets, or internal references. Only docs, changelogs, and release artifacts.
