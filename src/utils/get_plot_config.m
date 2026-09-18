function cfg = get_plot_config()
%GET_PLOT_CONFIG Plot styling, level colors/names, and collision-rate binning.
cfg.fs      = 18;
cfg.fs_ann  = 24;
cfg.lw_mean = 2.5;
cfg.lw_dyad = 0.9;
cfg.ms      = 7;
cfg.alpha_d = 0.20;
cfg.alpha_s = 0.18;

cfg.lv_col = [0.20 0.45 0.70;
              0.20 0.60 0.20;
              0.85 0.55 0.10;
              0.75 0.15 0.15];

cfg.lv_names = {'Level 1','Level 2','Level 3','Level 4'};

cfg.bin_sz   = 10;   % seconds per collision-rate time bin
cfg.max_time = 300;  % seconds of game time considered
end
