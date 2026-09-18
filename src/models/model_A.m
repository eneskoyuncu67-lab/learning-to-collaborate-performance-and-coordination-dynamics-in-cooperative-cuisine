function [glme_lv, b_A, p_A, bayes_A] = model_A(order_seq, lv_names)
%MODEL_A logit(outcome_bin) ~ order_pos + (1|dyad), fit per level, with
%   a BIC-approximated Bayes factor (Wagenmakers, 2007) for the
%   order_pos effect.
fprintf('\n============================================================\n');
fprintf('MODEL A: logit(outcome_bin) ~ order_pos + (1|dyad)\n');
fprintf('[fitglme | Binomial | logit link]\n');
fprintf('============================================================\n');

glme_lv = cell(4,1);
b_A     = nan(4,1); p_A = nan(4,1);
bayes_A = table();

for lv = 0:3
    T = order_seq(order_seq.level==lv,:);
    g = fitglme(T,'outcome_bin ~ order_pos + (1|dyad)',...
        'Distribution','Binomial','Link','logit');
    glme_lv{lv+1} = g;
    nm = g.CoefficientNames;
    b_A(lv+1) = g.Coefficients.Estimate(strcmp(nm,'order_pos'));
    p_A(lv+1) = g.Coefficients.pValue(strcmp(nm,'order_pos'));
    fprintf('\n--- %s (N=%d orders) ---\n', lv_names{lv+1}, height(T));
    disp(g.Coefficients(:,{'Name','Estimate','SE','tStat','pValue'}));
    fprintf('order_pos: beta=%.4f  OR=%.3f  %s\n',...
        b_A(lv+1), exp(b_A(lv+1)), conditional_pstr(p_A(lv+1)));

    g_null = fitglme(T,'outcome_bin ~ 1 + (1|dyad)','Distribution','Binomial','Link','logit');
    [BF10, ev] = bic_bayes_factor(g.ModelCriterion.BIC, g_null.ModelCriterion.BIC);
    fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
    bayes_A = [bayes_A; table(string(lv_names{lv+1}), BF10, string(ev), 'VariableNames',{'level','BF10','evidence'})];
end
end
