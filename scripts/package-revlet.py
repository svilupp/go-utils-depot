#!/usr/bin/env python3
"""Stage public Revlet documentation and the pinned live runtime beside a binary."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    source, depot, destination = (Path(arg).resolve() for arg in sys.argv[1:])
    public = depot / "revlet"
    for name in ("README.md", "CHANGELOG.md", "revlet.example.toml"):
        shutil.copyfile(public / name, destination / name)
    shutil.copyfile(depot / "LICENSE", destination / "LICENSE")
    shutil.copytree(public / "docs", destination / "docs")
    for name in ("TAILWIND-LICENSE", "MERMAID-LICENSE"):
        shutil.copyfile(source / "internal/web/assets" / name, destination / name)
    for name in ("pi/revlet-session.ts", "scripts/browser-comment.mjs"):
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source / name, target)

    # Package the checked-in pinned dependency, never an ambient local override.
    environment = dict(os.environ)
    environment.pop("REVLET_BP_ROOT", None)
    subprocess.run(
        [sys.executable, "scripts/package-live.py", str(destination / "browser")],
        cwd=source,
        env=environment,
        check=True,
    )
    browser = destination / "browser"
    shutil.copyfile(public / "docs/live-browser.md", browser / "README.md")
    # Recompute the runtime manifest after substituting public documentation.
    files = {
        path.relative_to(browser).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(browser.rglob("*"))
        if path.is_file() and path != browser / "provenance.json"
    }
    (browser / "provenance.json").write_text(
        json.dumps({"browser_pilot": "0.7.0", "sha256": files}, indent=2) + "\n"
    )


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: package-revlet.py SOURCE_DIR DEPOT_DIR DESTINATION")
    main()
