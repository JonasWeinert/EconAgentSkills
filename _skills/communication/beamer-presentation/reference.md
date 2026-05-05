# Beamer Presentation Reference

Detailed templates for academic economics Beamer slides that share assets with the underlying paper.

## 1. Beamer Preamble (`preamble-beamer.tex`)

```latex
% packages, theme, fonts, colors, frame title style
\usepackage{amsmath, amssymb, amsthm, mathtools, dsfont, bm}
\usepackage{booktabs, threeparttable, siunitx}
\usepackage{graphicx, tikz}
\usepackage[capitalize, noabbrev]{cleveref}

% Theme
\usetheme{metropolis}
\setbeamertemplate{navigation symbols}{}
\setbeamertemplate{footline}[frame number]
\setbeamercovered{transparent=20}

% Custom palette (matches Okabe-Ito blue used in figures)
\definecolor{paperblue}{HTML}{0072B2}
\definecolor{paperaccent}{HTML}{D55E00}
\setbeamercolor{frametitle}{bg=paperblue, fg=white}
\setbeamercolor{title}{fg=paperblue}
\setbeamercolor{structure}{fg=paperblue}
\setbeamercolor{alerted text}{fg=paperaccent}

% Theorem environments (lighter than the paper's)
\theoremstyle{definition}
\newtheorem{slidedef}{Definition}
\newtheorem{slideprop}{Proposition}
```

## 2. Master Deck (`slides.tex`)

```latex
\documentclass[aspectratio=169, 11pt]{beamer}

\input{preamble-beamer}
\input{../paper/tex/notation}        % SHARED notation file

\title{Title of the Paper}
\subtitle{(short and descriptive)}
\author{First Author \and Second Author}
\institute{University \\ \texttt{first@uni.edu}}
\date{Conference Name \\ Month Year}

\begin{document}

\begin{frame}[plain]\titlepage\end{frame}

% --- Body --------------------------------------------------------
\input{frame_motivation}
\input{frame_strategy}
\input{frame_results}
\input{frame_robustness}
\input{frame_conclusion}

% --- Backup ------------------------------------------------------
\appendix
\begin{frame}[plain]{Backup slides}\end{frame}
% \input{frame_backup_estimators}
% \input{frame_backup_mechanism}

\end{document}
```

## 3. Motivation Frame (`frame_motivation.tex`)

```latex
\begin{frame}{Why this matters}
  \begin{itemize}
    \item<1->\textbf{Big picture:} [substantive issue in one line].
    \item<2->\textbf{Specific puzzle:} [what we don't know].
    \item<3->\textbf{Stakes:} [policy or theory consequence].
  \end{itemize}

  \only<4>{
    \vspace{1em}
    \begin{block}{Headline}
      \large One sentence preview of the answer:
      \alert{[X causes Y, by Z\%]}.
    \end{block}}
\end{frame}

\begin{frame}{This paper}
  \begin{center}\Large
  \textbf{Question.}\\[0.4em]
  Does [TREATMENT] cause [OUTCOME] in [SETTING]?
  \end{center}

  \medskip
  \textbf{We:}
  \begin{itemize}
    \item Exploit [SOURCE OF VARIATION].
    \item Estimate [ESTIMAND] using [DESIGN].
    \item Find: \alert{\headlineEstimate{} (\headlineSE{})},
          or [X]\% relative to mean.
  \end{itemize}
\end{frame}
```

## 4. Strategy Frame (`frame_strategy.tex`)

```latex
\begin{frame}{Identification}
  \textbf{What's the variation?} [SOURCE OF VARIATION].

  \medskip
  \textbf{Identifying assumption.} Without [TREATMENT], treated and
  control units share the same trend in [OUTCOME].

  \medskip
  \textbf{Three pieces of supporting evidence:}
  \begin{enumerate}
    \item Pre-period leads jointly indistinguishable from zero
          ($p = [P]$).
    \item Placebo on [PLACEBO OUTCOME] yields a precise null.
    \item Pre-treatment characteristics balanced
          ($|\text{std diff}| < 0.10$).
  \end{enumerate}
\end{frame}

\begin{frame}{Estimating equation}
  \begin{equation*}
  y_{it} = \beta \cdot D_{it} + X_{it}^{\prime}\gamma
         + \alpha_i + \gamma_t + \varepsilon_{it}.
  \end{equation*}

  \begin{itemize}
    \item $D_{it}$: treatment indicator.
    \item $\alpha_i, \gamma_t$: unit and time fixed effects.
    \item Cluster SEs at the [LEVEL] level.
    \item Staggered timing: report Callaway-Sant'Anna as preferred,
          TWFE as benchmark.
  \end{itemize}
\end{frame}
```

## 5. Results Frame (`frame_results.tex`)

```latex
\begin{frame}{Main result: dynamic effect}
  \begin{center}
    \includegraphics[width=0.85\textwidth]{../paper/figs/fig_event_study.pdf}
  \end{center}

  \medskip
  \alert{Takeaway.} Pre-trends flat; effect rises in years 1-3 and
  stabilizes at \headlineEstimate{} units.
\end{frame}

\begin{frame}{Main result: regression}
  \resizebox{\textwidth}{!}{\input{../paper/tabs/table_main.tex}}

  \medskip
  \alert{Headline:} \headlineEstimate{} (\headlineSE{}) -- about [X]\%
  relative to the sample mean.
\end{frame}
```

If the paper table is too wide, generate a slide-friendly variant in
`paper/code/r/make_tables.R` (or the Stata equivalent) that drops
auxiliary specifications.

## 6. Robustness Frame (`frame_robustness.tex`)

```latex
\begin{frame}{Robustness: results hold across specs}
  \begin{itemize}
    \item[\checkmark] Two-way clustering: SEs similar.
    \item[\checkmark] Wild cluster bootstrap (G = [G] clusters).
    \item[\checkmark] Alternative DiD estimators (CS, SA, BJS) within [X]\%.
    \item[\checkmark] Restrict to [SUBSAMPLE]: estimate stable.
    \item[\checkmark] Placebo on [PLACEBO OUTCOME]: precise null.
  \end{itemize}

  \medskip
  \textbf{See appendix slides A.1-A.4 for details.}
\end{frame}
```

## 7. Conclusion Frame (`frame_conclusion.tex`)

```latex
\begin{frame}{Takeaways}
  \begin{enumerate}
    \item \textbf{Headline:} \headlineEstimate{} effect of [TREATMENT]
          on [OUTCOME].
    \item \textbf{Mechanism:} [Channel].
    \item \textbf{Policy:} [Implication].
  \end{enumerate}

  \vfill
  \begin{center}
    \large Thank you.\\[0.4em]
    \normalsize \texttt{first@uni.edu}\\
    Paper: \texttt{example.com/paper.pdf}
  \end{center}
\end{frame}
```

End on the takeaways, not on "Questions?".

## 8. Backup Slides

```latex
\appendix

\begin{frame}{A.1 \quad DiD estimator comparison}
  \resizebox{\textwidth}{!}{\input{../paper/tabs/table_did_estimators.tex}}
\end{frame}

\begin{frame}{A.2 \quad Wild cluster bootstrap}
  \resizebox{\textwidth}{!}{\input{../paper/tabs/table_wild_boot.tex}}
\end{frame}

\begin{frame}{A.3 \quad Heterogeneity by [DIMENSION]}
  \begin{center}
    \includegraphics[width=0.85\textwidth]{../paper/figs/fig_hetero.pdf}
  \end{center}
\end{frame}
```

Backup slides should be standalone — assume the audience question is just "show me X". Include the figure or table; minimal prose.

## 9. Animation Recipes

### Reveal the punchline last

```latex
\begin{frame}{Headline}
  \begin{itemize}
    \item<1-> Pre-trends: \alert{flat}.
    \item<2-> Effect: \alert{rises in years 1-3}.
    \item<3-> Steady-state: \alert{\headlineEstimate{} units}.
  \end{itemize}
\end{frame}
```

### Layer figures

Build the figure in stages by exporting two or three versions from
ggplot/matplotlib (`fig_event_static.pdf`, `fig_event_with_ci.pdf`,
`fig_event_full.pdf`) and `\only<n>` between them.

## 10. Customizing `metropolis`

```latex
\metroset{
  block=fill,                 % filled background for definition blocks
  background=light,           % white background
  numbering=fraction,         % "12/40" instead of "12"
  progressbar=frametitle,     % thin progress bar under frame title
  sectionpage=progressbar,    % section divider with progress
}
```

For more aggressive styling, switch the title font and accent colors:

```latex
\setbeamerfont{frametitle}{family=\rmfamily, size=\large, series=\bfseries}
\setbeamerfont{title}{family=\rmfamily, size=\Huge,  series=\bfseries}
```

## 11. Reproducibility (DIME applied)

- Slides import the same `notation.tex` as the paper. Drift is impossible.
- Slides import figures from `../paper/figs/` and tables from `../paper/tabs/`. Single rebuild path.
- Add `slides.pdf` to the project `Makefile`:

```makefile
slides: slides/slides.pdf

slides/slides.pdf: slides/slides.tex paper/tabs/*.tex paper/figs/*.pdf
	cd slides && latexmk -pdf slides
```

- For talks where you change the headline number live (sensitivity analysis), regenerate the figure/table on the spot via the analysis script — never edit the `.tex` by hand.
