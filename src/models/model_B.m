function [lme_ct, b_B, p_B, r2_B_lv, bayes_B] = model_B(order_seq, lv_names)
%MODEL_B completion_time_s ~ order_pos + (1|dyad), completed orders
%   only, with a BIC-approximated Bayes factor for the order_pos
%   effect. Reported estimates use the REML default; the Bayes factor
%   refits both the full and null model with FitMethod 'ML', since
%   comparing BIC across differing fixed-effects structures requires
%   ML fits.
fprintf('\n============================================================\n');
fprintf('MODEL B: completion_time_s ~ order_pos + (1|dyad)\n');
fprintf('[fitlme | completed orders only]\n');
fprintf('============================================================\n');

lme_ct  = cell(4,1);
b_B     = nan(4,1); p_B = nan(4,1); r2_B_lv = nan(4,1);
bayes_B = table();

for lv = 0:3
    T = order_seq(order_seq.level==lv & order_seq.outcome_bin==1,:);
    if height(T) < 5
        fprintf('%-10s insufficient data\n', lv_names{lv+1});
        bayes_B = [bayes_B; table(string(lv_names{lv+1}), NaN, "insufficient data", 'VariableNames',{'level','BF10','evidence'})];
        continue;
    end
    g = fitlme(T,'completion_time_s ~ order_pos + (1|dyad)');
    lme_ct{lv+1} = g;
    nm = g.CoefficientNames;
    b_B(lv+1)     = g.Coefficients.Estimate(strcmp(nm,'order_pos'));
    p_B(lv+1)     = g.Coefficients.pValue(strcmp(nm,'order_pos'));
    r2_B_lv(lv+1) = g.Rsquared.Ordinary;
    fprintf('\n--- %s (N=%d completed orders) ---\n', lv_names{lv+1}, height(T));
    disp(g.Coefficients(:,{'Name','Estimate','SE','tStat','pValue'}));
    fprintf('R2_marginal = %.4f\n', r2_B_lv(lv+1));

    g_full_ml = fitlme(T,'completion_time_s ~ order_pos + (1|dyad)','FitMethod','ML');
    g_null_ml = fitlme(T,'completion_time_s ~ 1 + (1|dyad)','FitMethod','ML');
    [BF10, ev] = bic_bayes_factor(g_full_ml.ModelCriterion.BIC, g_null_ml.ModelCriterion.BIC);
    fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
    bayes_B = [bayes_B; table(string(lv_names{lv+1}), BF10, string(ev), 'VariableNames',{'level','BF10','evidence'})];
end
end
