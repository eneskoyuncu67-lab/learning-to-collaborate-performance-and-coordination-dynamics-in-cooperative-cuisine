function [lm_F, b_F, p_F, r2_F, bayes_F] = model_F(dyad_summ, lv_names)
%MODEL_F comp_rate ~ pd, dyad-level OLS, all 4 levels, with a
%   BIC-approximated Bayes factor. Does deviation from a single stable
%   collaboration pattern (Schroder et al., 2025, Eq. 3; see the
%   pattern-dynamics caveat in dyadic_learning_analysis.m) predict a
%   dyad's overall completion rate in that level?
fprintf('\n============================================================\n');
fprintf('MODEL F: comp_rate ~ pd\n');
fprintf('[fitlm | OLS | dyad-level means | Schroder et al. (2025) Eq. 3]\n');
fprintf('============================================================\n');

lm_F    = cell(4,1);
b_F     = nan(4,1); p_F = nan(4,1); r2_F = nan(4,1);
bayes_F = table();

for lv = 0:3
    T = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.pd),:);
    if height(T) < 4
        fprintf('%-10s insufficient data\n', lv_names{lv+1});
        bayes_F = [bayes_F; table(string(lv_names{lv+1}), NaN, "insufficient data", 'VariableNames',{'level','BF10','evidence'})];
        continue;
    end
    g = fitlm(T,'comp_rate ~ pd');
    lm_F{lv+1} = g;
    b_F(lv+1)  = g.Coefficients.Estimate(2);
    p_F(lv+1)  = g.Coefficients.pValue(2);
    r2_F(lv+1) = g.Rsquared.Ordinary;
    fprintf('\n--- %s (n=%d dyads) ---\n', lv_names{lv+1}, height(T));
    disp(g.Coefficients(:,{'Estimate','SE','tStat','pValue'}));
    fprintf('R2 = %.4f\n', r2_F(lv+1));

    g_null = fitlm(T,'comp_rate ~ 1');
    [BF10, ev] = bic_bayes_factor(g.ModelCriterion.BIC, g_null.ModelCriterion.BIC);
    fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
    bayes_F = [bayes_F; table(string(lv_names{lv+1}), BF10, string(ev), 'VariableNames',{'level','BF10','evidence'})];
end
end
