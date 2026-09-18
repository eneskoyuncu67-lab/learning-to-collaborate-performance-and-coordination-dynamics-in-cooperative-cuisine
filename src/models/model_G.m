function [glme_G, b_G, p_G, bayes_G] = model_G(it_session)
%MODEL_G intertwinement ~ level + (1|dyad), all dyads pooled across all
%   4 levels, with a BIC-approximated Bayes factor for the level
%   effect. Does intertwinement differ systematically by kitchen
%   layout, mirroring the paper's own Figure 5 comparison across
%   scenarios? Reported estimates use the REML default; the Bayes
%   factor refits both models with FitMethod 'ML' for the same reason
%   as model_B/model_C.
fprintf('\n============================================================\n');
fprintf('MODEL G: intertwinement ~ level + (1|dyad)\n');
fprintf('[fitlme | level as a categorical fixed effect, pooled across all 4 levels]\n');
fprintf('============================================================\n');

if isempty(it_session)
    fprintf('insufficient data\n');
    glme_G = []; b_G = []; p_G = [];
    bayes_G = table(NaN, "insufficient data", 'VariableNames',{'BF10','evidence'});
    return;
end

T = it_session;
T.level_cat = categorical(T.level);

glme_G = fitlme(T, 'intertwinement ~ level_cat + (1|dyad)');
disp(glme_G.Coefficients(:,{'Name','Estimate','SE','tStat','pValue'}));
fprintf('\nOmnibus test of level effect:\n');
disp(anova(glme_G));
b_G = glme_G.Coefficients.Estimate;
p_G = glme_G.Coefficients.pValue;

g_full_ml = fitlme(T,'intertwinement ~ level_cat + (1|dyad)','FitMethod','ML');
g_null_ml = fitlme(T,'intertwinement ~ 1 + (1|dyad)','FitMethod','ML');
[BF10, ev] = bic_bayes_factor(g_full_ml.ModelCriterion.BIC, g_null_ml.ModelCriterion.BIC);
fprintf('Bayes factor: BF10 = %.2f (%s)\n', BF10, ev);
bayes_G = table(BF10, string(ev), 'VariableNames',{'BF10','evidence'});
end
