---
name: skill-name
description: >
  Does a specific economics workflow with clear, reproducible steps.
  Use when the user asks for [trigger phrases], [method names], or [expected outputs].
workflow_stage: analysis  # data | analysis | writing | communication
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: JonasWeinert
version: 1.0.0
tags:
  - tag1
  - tag2
---

# Skill Name

## Purpose

Describe the specific problem this skill solves for economists. Keep this short; `SKILL.md` should be the fast-loading operating procedure, not a full tutorial.

## When to Use

- Use this skill when you need to...
- This is especially helpful for...

## Decision Policy

This skill follows the repo-wide [Agent Policy](AGENT_POLICY.md).

**ASK before proceeding** (blocking):

1. [substantive question 1 — something that changes the answer]
2. [substantive question 2 — something irreversible]
3. [substantive question 3 — anything PII-related, raw-data-touching, or opinion-load-bearing]

**DEFAULT + flag** (use this default; tell the user how to override):

- [default 1] — override with [...]
- [default 2] — override with [...]

**DOCUMENT and proceed** (write into the decisions log at the top of the script):

- [inferred choice 1]
- [inferred choice 2]

`PROCEED` items follow the cross-cutting rules in `AGENT_POLICY.md`.

## Instructions

Follow these steps to complete the task:

### Step 1: Understand the Context

Before generating any code, ask the user:
- What is the research question?
- What data format are you working with?
- What software/language preference do you have?

### Step 2: Generate the Output

Based on the context, generate [code/document/analysis] that:

1. **Follows best practices** - Use standard conventions for [Stata/R/Python/LaTeX]
2. **Is reproducible** - Include comments explaining each step
3. **Handles edge cases** - Check for missing data, outliers, etc.

### Step 3: Verify and Explain

After generating output:
- Explain what the code does
- Highlight any assumptions made
- Suggest next steps or improvements

## Example Prompts

Users might invoke this skill with prompts like:

- "Run a difference-in-differences analysis on my treatment data"
- "Clean this dataset and create summary statistics"
- "Write the methodology section for my regression analysis"

## Example Output

Keep examples short. Put full runnable examples in `examples/` and point to them here.

- `examples/example.do` - Stata workflow
- `examples/example.R` - R workflow
- `examples/example.py` - Python workflow

## Requirements

### Software
- Stata 17+ / R 4.0+ / Python 3.10+

### Packages
- For R: `tidyverse`, `fixest`, `modelsummary`
- For Python: `pandas`, `statsmodels`, `linearmodels`
- For Stata: Built-in commands

## Best Practices

When using this skill, ensure:

1. **Data is properly formatted** - Variables named clearly, no special characters
2. **Sample is defined** - Clear inclusion/exclusion criteria
3. **Output is documented** - All results are reproducible

## Common Pitfalls

Avoid these mistakes:
- ❌ Running analysis without checking data quality first
- ❌ Ignoring missing values or outliers
- ❌ Not specifying robust standard errors when needed

## References

- [Relevant documentation or textbook]
- [Academic paper on methodology]
- [Software package documentation]

## Maintenance

- Keep `SKILL.md` under 500 lines.
- Use one-level references such as `reference.md`, `examples.md`, or `examples/example.py`.
- Add `## Additional Resources` links when a skill has support files.
- After editing, run `python scripts/link_references.py`, then `python scripts/generate_manifest.py`, then `python scripts/validate_skills.py`.
