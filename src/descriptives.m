function desc = descriptives(order_seq, coll_t, lv_names)
%DESCRIPTIVES Distributional summary of key variables per level.
%   Includes the skewness of completion time, since the mixed models
%   fit to it (Model B) assume approximately normal residuals -- a
%   strongly right-skewed distribution is worth flagging as a caveat.
desc = table();

for lv = 0:3
    To = order_seq(order_seq.level==lv,:);
    Tc = To(To.outcome_bin==1,:);

    n_dyads   = numel(unique(To.dyad));
    comp_rate = mean(To.outcome_bin);
    ct_mean   = mean(Tc.completion_time_s);
    ct_sd     = std(Tc.completion_time_s);
    ct_skew   = skewness(Tc.completion_time_s);

    if lv < 3
        Tcol    = coll_t(coll_t.level==lv,:);
        cr_mean = mean(Tcol.collision_rate);
        cr_sd   = std(Tcol.collision_rate);
    else
        cr_mean = NaN; cr_sd = NaN;
    end

    desc = [desc; table(string(lv_names{lv+1}), height(To), n_dyads, comp_rate, ...
        ct_mean, ct_sd, ct_skew, cr_mean, cr_sd, ...
        'VariableNames',{'level','N_orders','n_dyads','completion_rate',...
        'mean_completion_time_s','sd_completion_time_s','skew_completion_time',...
        'mean_collision_rate','sd_collision_rate'})];
end
end
