function [lme_coll, b_C, p_C, r2_C, bayes_C] = model_C(coll_t, lv_names)
%MODEL_C collision_rate ~ time_bin + (1|dyad), levels 1-3 only (Level 4
%   excluded by design), with a BIC-approximated Bayes factor for the
%   time_bin effect. Reported estimates use the REML default; the Bayes
%   factor refits both models with FitMethod 'ML' for the same reason
%   as model_B.
fprintf('\n============================================================\n');
fprintf('MODEL C: collision_rate ~ time_bin + (1|dyad)\n');
fprintf('[fitlme | Levels 1-3 only — Level 4 excluded by design]\n');
fprintf('============================================================\n');

lme_coll = cell(3,1);
b_C      = nan(3,1); p_C = nan(3,1); r2_C = nan(3,1);
bayes_C  = table();

for lv = 0:2
    T = coll_t(coll_t.level==lv,:);
    g = fitlme(T,'collision_rate ~ time_bin + (1|dyad)');
    lme_coll{lv+1} = g;
    nm = g.CoefficientNames;
    b_C(lv+1)  = g.Coefficients.Estimate(strcmp(nm,'time_bin'));
    p_C(lv+1)  = g.Coefficients.pValue(strcmp(nm,'time_bin'));
    r2_C(lv+1) = g.Rsquared.Ordinary;
    fprintf('\n--- %s (N=%d observations) ---\n', lv_names{lv+1}, height(T));
    disp(g.Coefficients(:,{'Name','Estimate','SE','tStat','pValue'}));
    fprintf('R2_marginal = %.4f\n', r2_C(lv+1));

    g_full_ml = fitlme(T,'collision_rate ~ time_bin + (1|dyad)','FitMethod','ML');
    g_null_ml = fitlme(T,'collision_rate ~ 1 + (1|dyad)','FitMethod','ML');
    [BF10, ev] = bic_bayes_factor(g_full_ml.ModelCriterion.BIC, g_null_ml.ModelCriterion.BIC);
    fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
    bayes_C = [bayes_C; table(string(lv_names{lv+1}), BF10, string(ev), 'VariableNames',{'level','BF10','evidence'})];
end
end
