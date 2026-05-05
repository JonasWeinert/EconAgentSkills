# Academic Paper Writer Reference

Templates and recipes for the standard sections of an empirical economics paper. Use as the canonical patterns when drafting or revising.

## 1. The Five-Paragraph Introduction

Every introduction has the same five jobs. Doing them in the right order is half the battle.

**Paragraph 1 — Motivation.**
Start with the question and why a non-specialist economist should care. Avoid "This paper examines"; lead with the substantive issue. End the paragraph with a sentence that sharpens to a specific question.

**Paragraph 2 — What this paper does.**
Topic sentence: "We study X in setting Y, exploiting Z." Specify the data, the sample, and the identifying variation in three sentences.

**Paragraph 3 — Identification.**
One paragraph version of the identification argument (see § 4 below for the full-section version). End with a sentence that previews the supporting evidence ("We document parallel trends in event-study form, and a placebo on outcome P yields a precise null").

**Paragraph 4 — Headline result.**
"We find ..." with a number and a magnitude in interpretable units. Then 1-2 sentences on what the result implies.

**Paragraph 5 — Contribution to literature.**
Three to five named strands. For each, state the closest paper and what is new here. Avoid "we extend" without saying how.

(Optional Paragraph 6 — Road map.)
Used in field journals; often dropped in AER/QJE-style intros where the structure is self-evident.

## 2. The Abstract (~100-150 words, 5 sentences)

1. The economic question.
2. The setting and identifying variation.
3. The headline finding with a number.
4. A second-order finding (heterogeneity, mechanism, or robustness).
5. The contribution / implication.

```
We study [QUESTION] in [SETTING]. Exploiting [VARIATION], we estimate
[ESTIMAND]. We find that [HEADLINE: a one-X change increases Y by Z%].
The effect is [LARGER / CONCENTRATED / DRIVEN BY] in [SUBGROUP/CHANNEL],
consistent with [MECHANISM]. Our findings imply [POLICY / THEORY].
```

## 3. Data Section

Order:

1. **Sources.** One paragraph per source. Period covered, unit of observation, sample frame.
2. **Sample construction.** Explicit filter list with N at each step.
3. **Variable construction.** Anything non-obvious (deflation, residualization, log/level choice).
4. **Summary statistics.** `Cref` to Table 1; one sentence on what the table shows.
5. **For RCTs:** balance table; `Cref` to Table 2; one sentence interpretation.

Sample-construction template:

```
Our sample is constructed in four steps. We start from [POPULATION]
([N0] observations). We restrict to [INCLUSION CRITERION 1] (N = [N1])
to focus on [REASON]. We drop [EXCLUSION CRITERION] (N = [N2]) because
[REASON]. We require non-missing [KEY VAR] (N = [N3]). The final sample
is [N3] [UNITS] observed [TIMES].
```

## 4. Identification Section (full)

```
\subsection{Empirical Strategy}\label{sec:strategy}

Our research design exploits [SOURCE OF VARIATION]. The identifying
assumption is that, absent [TREATMENT], [TREATED UNITS] would have
followed the same trend in [OUTCOME] as [CONTROL UNITS]. We provide
three pieces of evidence in support of this assumption.

\textit{Pre-trends.} We estimate the event-study specification
%
\begin{equation}\label{eq:event_study}
y_{it} = \sum_{e \neq -1} \beta_e \cdot \ind\{t - g_i = e\}
       + \alpha_i + \gamma_t + \varepsilon_{it},
\end{equation}
%
where $g_i$ is unit $i$'s treatment date and $\beta_e$ traces out the
effect at event time $e$. \Cref{fig:event} shows that the pre-period
coefficients are jointly indistinguishable from zero (joint $p =
[P]$).

\textit{Placebo.} Applying the same design to [PLACEBO OUTCOME]
yields a precise null effect of [POINT ESTIMATE] (\Cref{tab:placebo}).

\textit{Balance.} Pre-treatment characteristics are balanced across
treatment cohorts (\Cref{tab:balance}); standardized differences are
all below 0.10.

The remaining identification concern is [HONEST CONCERN]; we address
it through [BOUNDING / IV / SUBSAMPLE / ALTERNATIVE COMPARISON GROUP]
in \Cref{sec:robustness}.
```

If treatment is staggered, mention which heterogeneity-robust DiD
estimator the main results use (Callaway-Sant'Anna, Sun-Abraham, BJS,
de Chaisemartin-D'Haultfoeuille — see `r-econometrics`,
`stata-regression`, or `python-panel-data` skills).

## 5. Results Section

Lead with the headline coefficient before walking through the table.
Pin the paper-wide convention: "main effect first, controls second,
fixed effects third, robustness in the next section."

```
\section{Results}\label{sec:results}

\Cref{tab:main} presents our main results. Column~(1) reports a baseline
specification with no controls. The point estimate on
[TREATMENT VARIABLE] is [b] ([se]), statistically significant at the
[1/5/10] percent level.

Column~(2) adds [CONTROL SET]. The estimate moves to [b] ([se]),
[stable / smaller / larger]. Column~(3) adds [FIXED EFFECTS], yielding
[b] ([se]); this is our preferred specification.

To gauge economic significance, [HEADLINE NUMBER] corresponds to a
[X]% increase relative to the sample mean of [MEAN]. Equivalently, a
one standard deviation increase in [TREATMENT] is associated with a
[Y]\% [increase / decrease] in [OUTCOME].
```

Use macros for the headline numbers in the body so they update with the
script that generated them:

```latex
% In tex/numbers.tex (sourced by paper.tex)
\newcommand{\headlineEstimate}{0.082}
\newcommand{\headlineSE}{0.015}
\newcommand{\headlineMean}{1.34}

% In body:
The treatment effect is \headlineEstimate\ (\headlineSE), or
$\sim$\,\round{\fpeval{100*\headlineEstimate/\headlineMean}}\% of the
sample mean.
```

## 6. Robustness Section

A robustness ladder:

```
\section{Robustness}\label{sec:robustness}

\Cref{tab:robust} reports four robustness checks of our preferred
specification. Column~(1) reproduces the main result for reference.
Column~(2) clusters two-way (unit and year) instead of one-way; the
point estimate is unchanged and the standard error is similar.
Column~(3) restricts to [SUBSAMPLE] to address [CONCERN]. Column~(4)
uses [ALTERNATIVE ESTIMATOR / OUTCOME / CONTROL SET]. In every
specification the point estimate lies within [+/- X%] of the baseline
and remains significant at the [1/5] percent level.

\paragraph{Pre-trends and event study.} \Cref{fig:event} confirms that
pre-period coefficients are economically and statistically
indistinguishable from zero, while post-period coefficients trace out
[SHAPE].

\paragraph{Placebo.} \Cref{tab:placebo} reports the same specification
with [PLACEBO OUTCOME]. The estimated effect is [PRECISE NULL].

\paragraph{Sensitivity to bandwidth / specification choices.} For RDD,
we report estimates over $[h/2, h, 2h]$. For DiD, we compare TWFE,
Callaway-Sant'Anna, Sun-Abraham, and BJS estimators
(\Cref{tab:did_estimators}); all yield similar magnitudes.
```

## 7. Conclusion (1 page, 3-4 paragraphs)

1. Restate question and answer with the headline number.
2. Synthesize what we learn — not a summary of sections.
3. Limitations (honest, concrete).
4. Open questions for future work.

```
\section{Conclusion}\label{sec:conclusion}

This paper asks [QUESTION]. Exploiting [VARIATION], we find that
[HEADLINE NUMBER] [INTERPRETED]. The result is robust to [LADDER] and
holds across [HETEROGENEITY DIMENSION].

Our findings have two implications. For [POLICY DOMAIN], they imply
[IMPLICATION 1]. For [THEORETICAL DEBATE], they support [SIDE OF DEBATE]
and challenge [OPPOSING VIEW].

Several limitations warrant mention. First, [LIMITATION 1: scope].
Second, [LIMITATION 2: data]. Third, [LIMITATION 3: external validity].

Future research could [DIRECTION 1] and [DIRECTION 2]. We hope our
findings motivate further work on [BROADER QUESTION].
```

## 8. Response-to-Referees Letter

Most R&Rs hinge on the response letter, not the revised draft. Discipline:

- One file per referee plus one for the editor.
- Quote the referee's concern in italics; respond directly underneath.
- Reference the precise change in the manuscript ("see new \Cref{sec:robustness} and \Cref{tab:robust_alt}").
- Say "no" politely when warranted, with reasoning. Don't make changes you don't believe in.

Template:

```latex
\section*{Response to Referee 2}

We thank Referee 2 for thoughtful comments that improved the paper. We
respond to each point below; the corresponding changes in the
manuscript are referenced explicitly.

\subsection*{Comment 1: Identification under staggered timing}

\textit{``With treatment timing varying across units, the standard
two-way fixed effects estimator may be biased (Goodman-Bacon 2021).
The authors should report a heterogeneity-robust estimator.''}

We agree. In the revision we report Callaway-Sant'Anna (2021) as our
preferred estimator and TWFE as a benchmark. The two estimators agree
to within [X]\% (\Cref{tab:did_estimators}). The interaction-weighted
Sun-Abraham (2021) estimator yields a similar magnitude (column~(3)).

\subsection*{Comment 2: Inference with few clusters}

\textit{``With only [G] clusters, conventional cluster-robust standard
errors will under-cover...''}

In the revision we report wild cluster bootstrap p-values (Cameron,
Gelbach \& Miller 2008; MacKinnon \& Webb 2018) using \texttt{boottest}
in Stata / \texttt{fwildclusterboot} in R. The bootstrap-based
$p$-values agree with our conventional inference (\Cref{tab:wild_boot}).

[continue point by point]
```

## 9. Journal-Specific Deviations

| Journal             | Notable deviations                                                                  |
|---------------------|-------------------------------------------------------------------------------------|
| AER, AEJ            | Strict word limits; Online Appendix carries everything that doesn't fit             |
| QJE                 | Long introductions accepted; data section often very detailed                       |
| ReStud, JoE         | Strong technical detail expected; longer methods sections                           |
| AEJ-Applied         | Tight focus; clear identification; magnitudes interpreted in policy units           |
| JEEA                | European style; somewhat shorter empirics, often blended with theory                |
| JPE                 | Interest in "big picture" framing; willingness to publish theoretical contributions |
| Field journals      | Field-specific framing (labor, public, dev, IO); ground in the relevant literature  |

Always read the most-recent guidelines on the journal's website; conventions drift.

## 10. Reproducibility Discipline (DIME applied to writing)

- The repo for the paper contains: `paper.tex`, `tex/`, `tabs/` (generated), `figs/` (generated), `code/`, `data/processed/`, `Makefile`, `README.md`. See `latex-econ-model` for the full layout.
- Numbers in the prose come from `\input{tabs/...}` or from a `tex/numbers.tex` macro file regenerated by the analysis script.
- The Makefile rebuilds tables and figures before LaTeX, so a single `make` reproduces the PDF from a clean clone.
- Commit the manuscript and the analysis code together. Reviewers and replicators expect this.
