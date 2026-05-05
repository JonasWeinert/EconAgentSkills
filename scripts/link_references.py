#!/usr/bin/env python3
"""Link local progressive-disclosure files from SKILL.md files."""

from __future__ import annotations

from skill_utils import ROOT, skill_files


def resource_block(skill_dir) -> str:
    lines = ["## Additional Resources", ""]
    if (skill_dir / "reference.md").exists():
        lines.append("- `reference.md` - extended prompt patterns, templates, and quality checks")
    if (skill_dir / "examples.md").exists():
        lines.append("- `examples.md` - worked examples and sample outputs")
    if (skill_dir / "examples").exists():
        lines.append("- `examples/` - runnable or copyable implementation examples")
    if (skill_dir / "templates").exists():
        lines.append("- `templates/` - reusable project scaffolds or document templates")
    lines.append("")
    return "\n".join(lines)


def insert_block(text: str, block: str) -> str:
    if "## Additional Resources" in text:
        return text

    for marker in ("\n## Requirements", "\n## References", "\n## Changelog"):
        idx = text.find(marker)
        if idx != -1:
            return text[:idx].rstrip() + "\n\n" + block + text[idx:]

    return text.rstrip() + "\n\n" + block


def main() -> None:
    changed = []
    for path in skill_files():
        skill_dir = path.parent
        if not any((skill_dir / name).exists() for name in ("reference.md", "examples.md", "examples", "templates")):
            continue
        text = path.read_text(encoding="utf-8")
        new_text = insert_block(text, resource_block(skill_dir))
        if new_text != text:
            path.write_text(new_text, encoding="utf-8")
            changed.append(path.relative_to(ROOT).as_posix())

    print(f"Linked resources in {len(changed)} skills:")
    for path in changed:
        print(f"- {path}")


if __name__ == "__main__":
    main()
