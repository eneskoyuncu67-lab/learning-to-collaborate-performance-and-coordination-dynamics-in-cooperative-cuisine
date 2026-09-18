function [lm_E, b_E, p_E, r2_E, bayes_E] = model_E(dyad_summ, lv_names)
%MODEL_E comp_rate ~ intertwinement, dyad-level OLS, all 4 levels, with
%   a BIC-approximated Bayes factor. Does a more balanced resource-
%   sharing pattern (Schroder et al., 2025, Eq. 1) predict a dyad's
%   overall completion rate in that level?
fprintf('\n============================================================\n');
fprintf('MODEL E: comp_rate ~ intertwinement\n');
fprintf('[fitlm | OLS | dyad-level means | Schroder et al. (2025) Eq. 1]\n');
fprintf('============================================================\n');

lm_E    = cell(4,1);
b_E     = nan(4,1); p_E = nan(4,1); r2_E = nan(4,1);
bayes_E = table();

for lv = 0:3
    T = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.intertwinement),:);
    if height(T) < 4
        fprintf('%-10s insufficient data\n', lv_names{lv+1});
        bayes_E = [bayes_E; table(string(lv_names{lv+1}), NaN, "insufficient data", 'VariableNames',{'level','BF10','evidence'})];
        continue;
    end
    g = fitlm(T,'comp_rate ~ intertwinement');
    lm_E{lv+1} = g;
    b_E(lv+1)  = g.Coefficients.Estimate(2);
    p_E(lv+1)  = g.Coefficients.pValue(2);
    r2_E(lv+1) = g.Rsquared.Ordinary;
    fprintf('\n--- %s (n=%d dyads) ---\n', lv_names{lv+1}, height(T));
    disp(g.Coefficients(:,{'Estimate','SE','tStat','pValue'}));
    fprintf('R2 = %.4f\n', r2_E(lv+1));

    g_null = fitlm(T,'comp_rate ~ 1');
    [BF10, ev] = bic_bayes_factor(g.ModelCriterion.BIC, g_null.ModelCriterion.BIC);
    fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
    bayes_E = [bayes_E; table(string(lv_names{lv+1}), BF10, string(ev), 'VariableNames',{'level','BF10','evidence'})];
end
end
