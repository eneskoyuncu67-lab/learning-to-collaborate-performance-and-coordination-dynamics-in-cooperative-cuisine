function [lm_D, b_D, p_D, r2_D, bayes_D] = model_D(dyad_summ, lv_names)
%MODEL_D comp_rate ~ mean_coll_rate, dyad-level OLS, levels 1-3 only
%   (Level 4 excluded by design), with a BIC-approximated Bayes factor.
fprintf('\n============================================================\n');
fprintf('MODEL D: comp_rate ~ mean_coll_rate\n');
fprintf('[fitlm | OLS | dyad-level means | Levels 1-3 only]\n');
fprintf('============================================================\n');

lm_D    = cell(3,1);
b_D     = nan(3,1); p_D = nan(3,1); r2_D = nan(3,1);
bayes_D = table();

for lv = 0:2
    T = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.mean_coll_rate),:);
    if height(T) < 4
        fprintf('%-10s insufficient data\n', lv_names{lv+1});
        bayes_D = [bayes_D; table(string(lv_names{lv+1}), NaN, "insufficient data", 'VariableNames',{'level','BF10','evidence'})];
        continue;
    end
    g = fitlm(T,'comp_rate ~ mean_coll_rate');
    lm_D{lv+1} = g;
    b_D(lv+1)  = g.Coefficients.Estimate(2);
    p_D(lv+1)  = g.Coefficients.pValue(2);
    r2_D(lv+1) = g.Rsquared.Ordinary;
    fprintf('\n--- %s (n=%d dyads) ---\n', lv_names{lv+1}, height(T));
    disp(g.Coefficients(:,{'Estimate','SE','tStat','pValue'}));
    fprintf('R2 = %.4f\n', r2_D(lv+1));

    g_null = fitlm(T,'comp_rate ~ 1');
    [BF10, ev] = bic_bayes_factor(g.ModelCriterion.BIC, g_null.ModelCriterion.BIC);
    fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
    bayes_D = [bayes_D; table(string(lv_names{lv+1}), BF10, string(ev), 'VariableNames',{'level','BF10','evidence'})];
end
end
