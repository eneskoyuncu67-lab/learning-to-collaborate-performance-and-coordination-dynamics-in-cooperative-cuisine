%% Dyadic Learning Analysis — cooperative game study
%
%   Analyzes gameplay logs from pairs of participants ("dyads") completing
%   a cooperative delivery-style game across 4 difficulty levels. Tests
%   for within-session learning trends in order completion and timing,
%   whether player-avatar collisions relate to task success, and whether
%   three collaboration-dynamics metrics from Schroder et al. (2025) --
%   intertwinement (Eq. 1), unit fluidity (Eq. 2), and pattern dynamics
%   (Eq. 3) -- relate to a dyad's overall completion rate and differ by
%   kitchen layout. See README.md for the full writeup this accompanies
%   ("Learning to Collaborate: Performance and Coordination Dynamics in
%   Cooperative Cuisine").
%
%   This is the orchestrator script: it loads data, builds tables, and
%   calls into src/ for everything else. See README.md's "Project
%   structure" section for what each file under src/ does.
%
%   Expects a Gamelogs export under DATA_FOLDER and a set of
%   player_interactions_<dyad>, Level <N>.json files under IT_FOLDER (see
%   data/README.md for both layouts and schemas).
%
%   Intertwinement, fluidity, and pattern dynamics (Eq. 1-3) are cited
%   from:
%   Schroder F, Heinrich F and Kopp S (2025) Towards fluid human-agent
%   collaboration: From dynamic collaboration patterns to models of
%   theory of mind reasoning. Front. Robot. AI 12:1532693.
%   doi: 10.3389/frobt.2025.1532693
%
%   IMPORTANT CAVEAT on pattern dynamics: Schroder et al.'s Eq. 3 takes
%   the minimum, across a set of collaboration PATTERNS (e.g. task-based
%   vs. resource-based groupings of units), of the mean fluidity within
%   each pattern. The raw logs here carry no task/subtask-to-unit
%   linkage, so the only pattern set this data supports is a single
%   global pattern spanning all resource units -- pd therefore reduces
%   to the plain mean fluidity across all units for that dyad x level,
%   not the multi-pattern minimum the paper's own case study computes.
%   Intertwinement and fluidity themselves carry no such caveat; they
%   are computed exactly as defined, at the resource-unit level the raw
%   data supports.
%
%   Sections:
%     1. Data loading & table building
%     2. Descriptive statistics & distributions
%     3. Frequentist models (learning trends & coordination, Models A-D)
%     4. Collaboration-dynamics models (Models E-G, Schroder et al. 2025)
%     5. Bayesian model comparison (BIC-approximated Bayes factors)
%     6. Sample-size report
%     7. Figures
%
%   Requires the Statistics and Machine Learning Toolbox (fitglme,
%   fitlme, fitlm, skewness).

clear; clc; close all;

addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));

%% Configuration

saving_figures = 1;
figuredir      = '.';

% Point these at your own exports (see data/README.md).
baseFolder = fullfile('data', 'Gamelogs');           % game_events.jsonl per session
itFolder   = fullfile('data', 'PlayerInteractions'); % player_interactions_<dyad>, Level <N>.json

cfg = get_plot_config();

%% ===================== 1. Data loading & table building =====================

[order_seq, coll_t, bin_ctrs, n_bins, dyad_summ, interactions_tbl] = data_loading(baseFolder, itFolder, cfg);
[it_session, fluidity_tbl, pd_tbl, dyad_summ] = collaboration_metrics(interactions_tbl, dyad_summ);

%% ===================== 2. Descriptive statistics & distributions =====================

fprintf('\n============================================================\n');
fprintf('DESCRIPTIVE STATISTICS\n');
fprintf('============================================================\n');
desc_tbl = descriptives(order_seq, coll_t, cfg.lv_names);
disp(desc_tbl);

fprintf('\nSession-level intertwinement (mean over dyads, per level):\n');
disp(groupsummary(it_session, 'level', 'mean', 'intertwinement'));

fprintf('\nUnit fluidity Fu (mean over units, per level):\n');
disp(groupsummary(fluidity_tbl, 'level', {'mean','std'}, 'Fu'));

fprintf('\nPattern dynamics pd (mean over dyads, per level):\n');
disp(groupsummary(pd_tbl, 'level', 'mean', 'pd'));

%% ===================== 3. Frequentist models (learning & coordination) =====================

[glme_lv, b_A, p_A, bayes_A]         = model_A(order_seq, cfg.lv_names);
[lme_ct, b_B, p_B, r2_B_lv, bayes_B] = model_B(order_seq, cfg.lv_names);
[lme_coll, b_C, p_C, r2_C, bayes_C]  = model_C(coll_t, cfg.lv_names);
[lm_D, b_D, p_D, r2_D, bayes_D]      = model_D(dyad_summ, cfg.lv_names);

%% ===================== 4. Collaboration-dynamics models (Schroder et al., 2025) =====================

[lm_E, b_E, p_E, r2_E, bayes_E] = model_E(dyad_summ, cfg.lv_names);
[lm_F, b_F, p_F, r2_F, bayes_F] = model_F(dyad_summ, cfg.lv_names);
[glme_G, b_G, p_G, bayes_G]     = model_G(it_session);

%% ===================== 5. Bayesian model comparison =====================

fprintf('\n\n############################################################\n');
fprintf('BAYESIAN MODEL COMPARISON SUMMARY (BIC-approximated Bayes factors)\n');
fprintf('BF10 > 1 favors the effect; BF10 < 1 favors the null.\n');
fprintf('Method: Wagenmakers (2007), BF01 = exp((BIC_full - BIC_null)/2)\n');
fprintf('############################################################\n');

fprintf('\nModel A (order_pos):\n');       disp(bayes_A);
fprintf('\nModel B (order_pos):\n');       disp(bayes_B);
fprintf('\nModel C (time_bin):\n');        disp(bayes_C);
fprintf('\nModel D (mean_coll_rate):\n');  disp(bayes_D);
fprintf('\nModel E (intertwinement):\n');  disp(bayes_E);
fprintf('\nModel F (pd):\n');              disp(bayes_F);
fprintf('\nModel G (level):\n');           disp(bayes_G);

%% ===================== 6. Sample-size report =====================

print_sample_size_report(order_seq, coll_t, dyad_summ, it_session, cfg.lv_names);

%% ===================== 7. Figures =====================

res.glme_lv = glme_lv; res.b_A = b_A; res.p_A = p_A;
res.lme_ct  = lme_ct;  res.b_B = b_B; res.p_B = p_B; res.r2_B_lv = r2_B_lv;
res.lme_coll = lme_coll; res.b_C = b_C; res.p_C = p_C; res.r2_C = r2_C;
res.b_D = b_D; res.p_D = p_D; res.r2_D = r2_D;

make_all_figures(order_seq, coll_t, dyad_summ, it_session, pd_tbl, fluidity_tbl, ...
    res, bin_ctrs, n_bins, cfg, saving_figures, figuredir);

fprintf('\nAll done.\n');
