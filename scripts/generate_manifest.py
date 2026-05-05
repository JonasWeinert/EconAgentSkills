#!/usr/bin/env python3
"""Generate _skills/manifest.json from canonical SKILL.md files."""

from __future__ import annotations

from datetime import UTC, datetime

from skill_utils import ROOT, skill_files, skill_record, print_json


def main() -> None:
    skills = [skill_record(path) for path in skill_files()]
    manifest = {
        "name": "EconAgentSkills",
        "description": "Opinionated agent skills for economics research workflows: data, analysis, writing, communication.",
        "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat(),
        "skill_count": len(skills),
        "skills": skills,
    }

    out = ROOT / "_skills" / "manifest.json"
    out.write_text(
        __import__("json").dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print_json({"generated": out.relative_to(ROOT).as_posix(), "skill_count": len(skills)})


if __name__ == "__main__":
    main()
