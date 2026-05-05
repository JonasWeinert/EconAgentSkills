#!/usr/bin/env python3
"""Install selected skills into local agent skill directories."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from skill_utils import ROOT, WORKFLOW_STAGES, skill_files, skill_record

TARGETS = {
    "cursor": Path("~/.cursor/skills").expanduser(),
    "claude": Path("~/.claude/skills").expanduser(),
    "codex": Path("~/.codex/skills").expanduser(),
}

EXCLUDE_DIRS = {".git", ".history", "__pycache__"}


def copy_skill(src: Path, dst_root: Path) -> Path:
    dst = dst_root / src.name
    if dst.exists():
        shutil.rmtree(dst)

    def ignore(_dir: str, names: list[str]) -> set[str]:
        return {name for name in names if name in EXCLUDE_DIRS}

    shutil.copytree(src, dst, ignore=ignore)
    return dst


def select_skills(args: argparse.Namespace) -> list[Path]:
    records = [(path, skill_record(path)) for path in skill_files()]
    selected: list[Path] = []

    for path, record in records:
        if args.all:
            selected.append(path.parent)
            continue
        if args.stage and record["workflow_stage"] in args.stage:
            selected.append(path.parent)
            continue
        if args.skill and record["name"] in args.skill:
            selected.append(path.parent)

    return sorted(set(selected))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", choices=TARGETS, default="cursor", help="agent tool to install for")
    parser.add_argument("--dest", type=Path, help="override installation directory")
    parser.add_argument("--all", action="store_true", help="install every skill")
    parser.add_argument("--stage", action="append", choices=sorted(WORKFLOW_STAGES), help="install all skills in a workflow stage")
    parser.add_argument("--skill", action="append", help="install one skill by slug; repeatable")
    args = parser.parse_args()

    if not (args.all or args.stage or args.skill):
        parser.error("choose --all, --stage, or --skill")

    destination = args.dest.expanduser() if args.dest else TARGETS[args.target]
    destination.mkdir(parents=True, exist_ok=True)
    selected = select_skills(args)

    if not selected:
        print("No skills matched the requested selection.")
        return 1

    for skill_dir in selected:
        installed = copy_skill(skill_dir, destination)
        print(f"Installed {skill_dir.name} -> {installed}")

    print(f"\nInstalled {len(selected)} skill(s) into {destination}")
    print("Restart or reload your agent tool if it does not pick up new skills immediately.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
