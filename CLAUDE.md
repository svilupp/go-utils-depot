# go-utils-depot

Public binary distribution repo. Source code lives in `go-training-range/`.

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

Builds static binaries for all 5 platforms, packages them, generates checksums, and creates a GitHub release tagged `<tool>/<version>`.

Requires `go` and `gh` (authenticated to the svilupp account).

## Important

This is a public repo. Never commit source code, secrets, or internal references. Only docs, changelogs, and release artifacts.
