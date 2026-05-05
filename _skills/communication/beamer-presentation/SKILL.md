---
name: beamer-presentation
description: >
  Builds academic economics presentations in LaTeX Beamer that share the same `notation.tex` macros and `tabs/`/`figs/` outputs as the underlying paper, so a single rebuild keeps slides and paper in sync. Defaults to clean themes (`metropolis` / `default` with custom colors), 16:9 aspect ratio, time-budget-aware structure (15/20/45/60/90 min), incremental reveals, and DIME-aligned reproducibility (figures/tables produced by code, never screenshotted). Cross-links to `latex-econ-model`, `latex-tables`, `econ-visualization`, and `academic-paper-writer`.
  Use when the user asks for conference talk slides, seminar presentations, job-market talks, thesis defense slides, or wants to convert a paper into Beamer.
workflow_stage: communication
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: JonasWeinert
version: 2.0.0
tags:
  - LaTeX
  - Beamer
  - presentations
  - slides
  - reproducibility
  - dime
---

# Beamer Presentation

Build clean, content-first academic slides in LaTeX Beamer that are reproducibly linked to the paper. The default style is `metropolis`-themed, 16:9, with the same `notation.tex` and `tabs/`/`figs/` artifacts as the paper.

## Operating Principles

1. **Slides share the paper's source of truth.** Same `notation.tex`, same `tabs/*.tex`, same `figs/*.pdf`. Rerun the analysis once; both PDF and slides update together. Never re-typeset a number on a slide.
2. **One claim per slide.** If you need more, split.
3. **Headline, then evidence.** The frame title states the claim; the body shows the evidence. Reviewers in the audience are skimming.
4. **Structure to time.** A 20-minute talk is fundamentally different from a 90-minute seminar. Pin the time budget early; it determines depth, not just length.
5. **Backup, don't overload.** Move detail into the appendix; reach for backup slides during Q&A. Better to be asked than to drown the talk in detail.

## Decision Policy

This skill follows the repo-wide [Agent Policy](../../AGENT_POLICY.md).

**ASK before proceeding** (blocking):

1. Time budget (15-20 min conference / 45-60 min seminar / 75-90 min job-market talk / 10-15 min policy briefing).
2. Audience expertise (specialists / broader economists / non-economists).
3. The headline (one sentence the audience must remember).
4. What goes in the appendix vs. the main deck.

**DEFAULT + flag** (use this default; tell the user how to override):

- Theme `metropolis`, 16:9 aspect ratio, `metroset{numbering=fraction, progressbar=frametitle}`.
- Frame title states the claim, not the topic ("Treatment increases outcome by 8%" not "Results").
- Imports `notation.tex`, `tabs/`, `figs/` from the paper directory — single source of truth.
- Backup slides start at `\appendix`; one tightly-focused slide per anticipated question.
- End on takeaways; do not end on "Questions?".

**DOCUMENT and proceed** (write into the deck preamble comment):

- Time-budget allocation (slides per section).
- Which paper artifacts the deck imports.
- Any slide-only number that does not come from `tabs/` or `figs/` (rare; flag for review).

`PROCEED` items: slides imported from the paper's notation file; `latexmk` build; `\Cref{}` for cross-refs; `\alert{}` for the headline color (matched to figure palette).

## Pre-flight Checklist

- **Format.** Conference (15-20 min), seminar (45-60 min), job-market talk (75-90 min), policy briefing (10-15 min), thesis defense?
- **Audience.** Specialists in the same subfield, broader economists, or non-economists?
- **What's the headline?** State it now in one sentence.
- **What evidence is irreducibly part of the talk?** (Identification, main result, robustness summary at minimum.)
- **What goes in the backup?** (Detailed robustness, mechanism evidence, alternative specifications.)
- **Visual aids.** Are there figures more compelling than tables? Almost always: yes.

## Time Budget by Format

```
15-20 min conference talk
└── ~12-15 content slides
    Motivation (2)  Question (1)  Strategy (2)  Results (4-5)
    Robustness (1)  Conclusion (1)  +backup
    Rule of thumb: 1-2 minutes per slide; never more.

45-60 min seminar
└── ~25-35 content slides
    Add: literature, institutional setting, mechanism, validation,
    extended robustness. Spend longer on the identification frame.

75-90 min job-market talk
└── ~40-55 content slides + 15+ backup
    Audience expects the full chain: motivation, contribution, model,
    data, identification, results, mechanism, robustness, policy,
    conclusion. Plan for 30+ min of Q&A.

10-15 min policy briefing
└── ~6-10 content slides; figures only.
    Lead with the policy-relevant headline; minimize regression tables.
```

## Project Layout (paper + slides share assets)

```
project/
├── paper/
│   ├── paper.tex
│   ├── tex/
│   │   ├── notation.tex      # SHARED with slides
│   │   ├── preamble.tex
│   │   └── (sections)
│   ├── tabs/                 # SHARED
│   ├── figs/                 # SHARED
├── slides/
│   ├── slides.tex            # \input{../paper/tex/notation.tex}
│   ├── preamble-beamer.tex
│   └── (frame files, optional)
└── code/
```

The slide deck imports the same notation and references the same `tabs/` and `figs/` paths. This is DIME's [single source of truth](https://dimewiki.worldbank.org/Reproducible_Research) principle applied across artifacts.

## Frame Recipes

### Frame title = the claim, not the topic

```
BAD:   "Results"
BETTER: "Treatment increases outcome by 8% (p < 0.01)"
```

### Build complex claims incrementally

```latex
\begin{frame}{Treatment effect grows over time}
  \only<1>{\includegraphics[width=\textwidth]{figs/fig_event_static.pdf}}
  \only<2>{\includegraphics[width=\textwidth]{figs/fig_event_with_ci.pdf}}
  \only<3>{\includegraphics[width=\textwidth]{figs/fig_event_full.pdf}}

  \medskip
  \only<3>{\textbf{Takeaway:} effect rises monotonically through year~5.}
\end{frame}
```

### Tables on slides should fit in 6-8 rows

For talks, regenerate a slide-friendly table from the same regression with `esttab` `keep()`/`drop()` options or a separate `slides_tabs/` folder.

## Common Pitfalls

- Reading the slide. The slide is for the audience; the script is for you.
- Tables with 12 rows of fixed effects. Cut to the headline coefficient + clearly labeled FE/N.
- Equations no one will read. Show the estimating equation if it carries the identification; otherwise drop it.
- Figures from screenshots of regression output. Always export from code.
- A title slide with five logos and seven affiliations. One affiliation, one date, one venue.
- "Questions?" as the final slide. End on the takeaway; questions are implicit.
- 9-point font in a footnote no one will read. Cut the footnote.

## Additional Resources

- `reference.md` — extended patterns: theme tweaks, `metropolis` customization, equation reveal patterns, Q&A appendix structure, multi-author title page, animated coefficient plots.
- `examples/` — copyable Beamer files:
  - `examples/preamble-beamer.tex` — packages, theme, custom colors, frame title style
  - `examples/slides.tex` — master deck `\input{}`-ing notation + frame files
  - `examples/frame_motivation.tex` — motivation/question slide
  - `examples/frame_strategy.tex` — identification slide with equation
  - `examples/frame_results.tex` — main result slide with figure + takeaway
  - `examples/frame_robustness.tex` — robustness summary slide
  - `examples/frame_conclusion.tex` — takeaways slide

## Cross-Skill Routing

- For shared notation and the paper-side LaTeX scaffolding → `latex-econ-model` skill.
- For slide-friendly versions of regression tables → `latex-tables` skill (`keep()`, `drop()`, alternative `mtitles()`).
- For figures used on slides → `econ-visualization` skill (`width = 10 in, height = 5.5 in` for 16:9).
- For the underlying paper draft → `academic-paper-writer` skill.

## References

- Shapiro, [How to Give an Applied Micro Talk](https://www.brown.edu/Research/Shapiro/pdfs/applied_micro_slides.pdf) — still the canonical reference.
- McKenzie, [Tips on Giving an Effective Conference Presentation](https://blogs.worldbank.org/impactevaluations/tips-giving-effective-conference-presentation).
- Beamer User Guide — https://ctan.org/pkg/beamer.
- Metropolis theme — https://github.com/matze/mtheme.
- DIME Analytics, [Reproducible Research](https://dimewiki.worldbank.org/Reproducible_Research) — single-source-of-truth idea applied to slides.
