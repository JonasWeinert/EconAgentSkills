#!/usr/bin/env python3
"""Validate skill metadata and installability."""

from __future__ import annotations

import re
import sys

from skill_utils import ROOT, SLUG_RE, WORKFLOW_STAGES, parse_frontmatter, skill_files

REQUIRED = {"name", "description", "workflow_stage", "compatibility", "author", "version", "tags"}
TRIGGER_TERMS = ("Use when", "Use for", "Trigger on", "invoke for", "Invoke for")
SECRET_PATTERNS = (
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
)
SECRET_ASSIGNMENT_RE = re.compile(
    r"(?i)(api[_-]?key|secret|token)\s*[:=]\s*['\"]([^'\"]{12,})['\"]"
)
SAFE_PLACEHOLDERS = ("your", "example", "placeholder", "dummy", "test", "key_here")


def check_file(path) -> list[str]:
    rel = path.relative_to(ROOT).as_posix()
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")

    try:
        meta = parse_frontmatter(text)
    except ValueError as exc:
        return [f"{rel}: {exc}"]

    missing = sorted(REQUIRED - set(meta))
    if missing:
        errors.append(f"{rel}: missing frontmatter keys: {', '.join(missing)}")

    name = meta.get("name", "")
    if not SLUG_RE.match(name):
        errors.append(f"{rel}: invalid name '{name}'")
    if name and name != path.parent.name:
        errors.append(f"{rel}: name does not match directory '{path.parent.name}'")

    description = meta.get("description", "")
    if len(description) < 90:
        errors.append(f"{rel}: description is too short for reliable discovery")
    if not any(term in description for term in TRIGGER_TERMS):
        errors.append(f"{rel}: description should include trigger language like 'Use when'")

    stage = meta.get("workflow_stage")
    if stage not in WORKFLOW_STAGES:
        errors.append(f"{rel}: invalid workflow_stage '{stage}'")

    if len(text.splitlines()) > 500:
        errors.append(f"{rel}: SKILL.md exceeds 500 lines")

    support_names = ("reference.md", "examples.md", "examples", "templates")
    support_files = [name for name in support_names if (path.parent / name).exists()]
    if not support_files:
        errors.append(f"{rel}: missing progressive-disclosure support file")
    elif "## Additional Resources" not in text:
        errors.append(f"{rel}: support files exist but SKILL.md does not link them")

    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            errors.append(f"{rel}: possible secret-like value found")
    for match in SECRET_ASSIGNMENT_RE.finditer(text):
        value = match.group(2).lower()
        if not any(token in value for token in SAFE_PLACEHOLDERS):
            errors.append(f"{rel}: possible secret-like value found")

    return errors


def main() -> int:
    errors: list[str] = []
    files = skill_files()
    if not files:
        errors.append("No skills found under _skills/*/*/SKILL.md")

    for path in files:
        errors.extend(check_file(path))

    manifest = ROOT / "_skills" / "manifest.json"
    if not manifest.exists():
        errors.append("_skills/manifest.json is missing; run scripts/generate_manifest.py")

    if errors:
        print("Skill validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Skill validation passed for {len(files)} skills.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
