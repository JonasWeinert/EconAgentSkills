#!/usr/bin/env python3
"""Shared helpers for Awesome Econ AI skill tooling."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / "_skills"
WORKFLOW_STAGES = {
    "data",
    "analysis",
    "writing",
    "communication",
}


def skill_files() -> list[Path]:
    return sorted(
        path
        for path in SKILLS_ROOT.glob("*/*/SKILL.md")
        if path.is_file()
    )


def split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("missing opening YAML frontmatter")
    marker = "\n---\n"
    end = text.find(marker, 4)
    if end == -1:
        raise ValueError("missing closing YAML frontmatter")
    return text[4:end], text[end + len(marker) :]


def _strip_inline_comment(value: str) -> str:
    if " #" not in value:
        return value
    return value.split(" #", 1)[0].rstrip()


def parse_frontmatter(text: str) -> dict[str, Any]:
    """Parse the small YAML subset used by SKILL.md files.

    This avoids requiring PyYAML for installation and CI validation.
    """
    raw, _ = split_frontmatter(text)
    lines = raw.splitlines()
    parsed: dict[str, Any] = {}
    i = 0

    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        if ":" not in line or line.startswith(" "):
            i += 1
            continue

        key, value = line.split(":", 1)
        key = key.strip()
        value = _strip_inline_comment(value.strip())

        if value in {">", "|"}:
            block: list[str] = []
            i += 1
            while i < len(lines) and (lines[i].startswith(" ") or not lines[i].strip()):
                block.append(lines[i].strip())
                i += 1
            parsed[key] = " ".join(part for part in block if part).strip()
            continue

        if value == "":
            items: list[str] = []
            i += 1
            while i < len(lines) and lines[i].startswith("  - "):
                items.append(lines[i][4:].strip())
                i += 1
            parsed[key] = items
            continue

        if value.startswith("[") and value.endswith("]"):
            parsed[key] = [
                item.strip().strip("\"'")
                for item in value[1:-1].split(",")
                if item.strip()
            ]
        else:
            parsed[key] = value.strip("\"'")
        i += 1

    return parsed


def skill_record(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    meta = parse_frontmatter(text)
    stage = meta.get("workflow_stage")
    slug = meta.get("name", path.parent.name)
    support_files = [
        candidate.name
        for candidate in sorted(path.parent.iterdir())
        if candidate.name != "SKILL.md" and not candidate.name.startswith(".")
    ]
    return {
        "name": slug,
        "description": meta.get("description", ""),
        "workflow_stage": stage,
        "path": path.parent.relative_to(ROOT).as_posix(),
        "support_files": support_files,
        "tags": meta.get("tags", []),
        "compatibility": meta.get("compatibility", []),
        "version": meta.get("version", ""),
        "author": meta.get("author", ""),
    }


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
