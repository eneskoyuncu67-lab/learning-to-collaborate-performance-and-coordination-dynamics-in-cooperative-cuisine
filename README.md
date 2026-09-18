# Dyadic Learning Analysis (Cooperative Cuisine Study)

Analyzes gameplay logs from pairs of human participants ("dyads")
completing a cooperative delivery-style game (Cooperative Cuisine, built on
the *Overcooked!* task) across 4 kitchen layouts of increasing spatial
interdependence. Computes order completion and timing, player-avatar
collision rates, and three collaboration-dynamics metrics (intertwinement,
unit fluidity, and pattern dynamics), introduced by Schröder, Heinrich &
Kopp (2025). This analysis applies that same framework to a separate
human-human dataset. More broadly, this same approach, tracking
intertwinement, fluidity, and pattern dynamics over the course of a
session, could be adapted to examine the dynamic process of fluid
collaboration across time in other *Overcooked!*-style task environments,
in collaboration research involving either human or artificial agents.

This accompanies the report *"Learning to Collaborate: Performance and
Coordination Dynamics in Cooperative Cuisine"* (Enes Koyuncu, Bielefeld
University), which used the same 15-dyad dataset and Models A–D below.




## Project structure

```
dyadic-learning-analysis/
├── dyadic_learning_analysis.m   (orchestrator script — run this)
├── data/                        (your own exports go here — see data/README.md)
└── src/
    ├── utils/                   (shared helpers, one function per file)
    │   ├── parse_env_time.m
    │   ├── conditional_pstr.m
    │   ├── group_stats.m
    │   ├── bic_bayes_factor.m
    │   └── get_plot_config.m
    ├── data_loading.m           (reads game_events.jsonl + player_interactions_*.json)
    ├── collaboration_metrics.m  (intertwinement, fluidity, pattern dynamics)
    ├── descriptives.m
    ├── models/
    │   └── model_A.m ... model_G.m   (one file per model: frequentist fit + Bayes factor)
    ├── reporting.m
    └── figures.m
```

MATLAB only allows one externally-callable function per file (matching the
filename), so this follows that convention: each model (A–G) gets its own
file combining its frequentist fit and Bayes factor together, shared
helpers used across many files get their own small file, and the bigger
pipeline steps (data loading, collaboration metrics, figures) each expose
one entry-point function that internally organizes its own sub-steps.

## Data

This repository ships without raw data (see `data/README.md` for where to
place your own export of each). Two independent data sources are used:

**1. `game_events.jsonl` (one per session)**

Each play session is one folder containing a `game_events.jsonl` file (one
JSON object per line, an event log). Session folders are expected to be
named like `<dyadID>_..._level_<N>...` so the dyad ID and level can be
parsed from the folder name, and are searched recursively under
`data/Gamelogs/`. Relevant fields:

- `hook_ref`: `new_orders`, `completed_order`, `order_expired`, or
  `players_collide`
- `env_time`: an ISO-like timestamp (`...THH:MM:SS...`)
- `new_orders` / `order`: nested objects carrying an order `id` and,
  optionally, `start_time`

**2. `player_interactions_<dyad>, Level <N>.json` (one per dyad × level)**

Placed flat under `data/PlayerInteractions/`. Each file is a JSON object
keyed by game resource ("unit" in the paper's terms — e.g. a cutting
board, stove, or dispenser identified by its in-game coordinates, or a
dish identified by its type and a generated ID), where each value is a
chronological list of `[player, timestamp]` pairs. Illustrative example
only — not real data:

```json
{"<resource key>": [["0", "<timestamp>"], ["1", "<timestamp>"], ["-", "<timestamp>"]]}
```

`player` is `"0"`, `"1"`, or `"-"` (released/unattended — excluded, since it
carries no player attribution).

## Models

| Model | Formula | Scope | Data source |
|---|---|---|---|
| A | `logit(order completed) ~ order_pos + (1\|dyad)` (GLME) | all 4 levels | `game_events.jsonl` |
| B | `completion_time_s ~ order_pos + (1\|dyad)` (LME) | completed orders only | `game_events.jsonl` |
| C | `collision_rate ~ time_bin + (1\|dyad)` (LME) | levels 1–3 (no collisions at level 4) | `game_events.jsonl` |
| D | `comp_rate ~ mean_coll_rate` (dyad-level OLS) | levels 1–3 | `game_events.jsonl` |
| E | `comp_rate ~ intertwinement` (dyad-level OLS) | all 4 levels | `player_interactions_*.json` |
| F | `comp_rate ~ pd` (dyad-level OLS) | all 4 levels | `player_interactions_*.json` |
| G | `intertwinement ~ level + (1\|dyad)` (LME, pooled across levels) | all 4 levels | `player_interactions_*.json` |

Models A–C and G are fit with a random dyad intercept (`fitglme`/`fitlme`);
Models D–F are ordinary least-squares fits on per-dyad means (`fitlm`).

## Collaboration-dynamics metrics

Intertwinement, unit fluidity, and pattern dynamics are computed exactly as
defined in:

> Schröder, F., Heinrich, F., and Kopp, S. (2025). Towards fluid
> human-agent collaboration: From dynamic collaboration patterns to models
> of theory of mind reasoning. *Frontiers in Robotics and AI*, 12, 1532693.
> https://doi.org/10.3389/frobt.2025.1532693

- **Intertwinement** (Eq. 1, resource-based variant): per dyad × level, the
  mean over resources of `2 * min(share_p0, share_p1)`, where `share_p` is
  the fraction of a resource's interactions performed by player `p`. `1` =
  perfectly balanced 50/50 contribution on every resource; `0` = one player
  did everything alone.
- **Fluidity of unit assignment** (Eq. 2): per resource, `Fu = Tu / (n-1)`,
  where `Tu` counts how often the acting player changes between consecutive
  interactions with that resource, and `n` is the number of interactions.
- **Pattern dynamics** (Eq. 3): the minimum, across a set of collaboration
  patterns, of the mean fluidity of units within each pattern. **Caveat**:
  the raw logs here carry no task/subtask-to-unit linkage, so the only
  pattern set this data supports is a single global pattern spanning all
  resource units — `pd` therefore reduces to the plain mean `Fu` across all
  units for that dyad × level, not the multi-pattern minimum the paper's own
  qualitative case study computes. Intertwinement and fluidity carry no such
  caveat; they are computed exactly as defined.

## Bayesian model comparison

Every model above (A–G) additionally gets a BIC-approximated Bayes factor
for its focal predictor, comparing the full model against an
intercept-only null:

> Wagenmakers, E.-J. (2007). A practical solution to the pervasive problems
> of *p* values. *Psychonomic Bulletin & Review*, 14(5), 779–804.
> BF01 = exp((BIC_full − BIC_null) / 2)

Verbal evidence labels follow the conventions in Lee, M. D., & Wagenmakers,
E.-J. (2013). *Bayesian Cognitive Modeling: A Practical Course*. Cambridge
University Press. This needs no extra toolbox — it only uses the BIC
already reported by `fitglme`/`fitlme`/`fitlm`. Note: `fitlme` calls used
for Bayes factors set `'FitMethod','ML'` (not the REML default), since
comparing BIC across differing fixed-effects structures requires ML fits.

## Output

- Console: per-level model coefficient tables, Bayes factors, descriptive
  statistics, and a sample-size report.
- `fig1_learning_and_completion.png`: completion probability and completion
  time vs. order position, per level.
- `fig2_collision_analysis.png`: collision rate vs. game time, and dyad
  completion rate vs. mean collision rate, per level.
- `fig3_distributions.png`: completion time and collision rate
  distributions, per level.
- `fig4_intertwinement_by_level.png`: session-level intertwinement by
  kitchen layout.
- `fig5_pattern_dynamics_by_level.png`: pattern dynamics by kitchen layout.
- `fig6_fluidity_distributions.png`: per-unit fluidity distributions, per
  level.

## Requirements

MATLAB with the Statistics and Machine Learning Toolbox (`fitglme`,
`fitlme`, `fitlm`, `skewness`).

## Usage

1. Place your Gamelogs export under `data/Gamelogs/` and your
   player-interaction files under `data/PlayerInteractions/` (see
   `data/README.md`).
2. Run `dyadic_learning_analysis.m` from this folder.

## AI-assisted development

This repository's code was developed with the assistance of **Claude
Code** (Anthropic). Specifically:

AI-assisted development

This repository's code was developed with the assistance of Claude Code (Anthropic). The original single-file analysis (Models A–D) was written for and reported in the accompanying study "Learning to Collaborate: Performance and Coordination Dynamics in Cooperative Cuisine." Claude Code was used to restructure that script into this multi-file project and to extend the analysis with Models E–G and the Bayesian model-comparison layer. 



