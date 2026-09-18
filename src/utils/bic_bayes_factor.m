function [BF10, evidence] = bic_bayes_factor(bic_full, bic_null)
%BIC_BAYES_FACTOR Approximate Bayes factor from a BIC difference
%   (Wagenmakers, 2007, J. Math. Psych.). BF10 > 1 favors the model
%   with the extra effect over the intercept-only null; BF10 < 1
%   favors the null. This only requires the BIC already reported by
%   fitglme/fitlme/fitlm, so it needs no extra toolbox.
BF01 = exp((bic_full - bic_null)/2);
BF10 = 1/BF01;
evidence = classify_bf(BF10);
end

function s = classify_bf(BF10)
%CLASSIFY_BF Verbal label for a Bayes factor (Lee & Wagenmakers, 2013).
if BF10 > 100,       s = 'extreme evidence for effect';
elseif BF10 > 30,    s = 'very strong evidence for effect';
elseif BF10 > 10,    s = 'strong evidence for effect';
elseif BF10 > 3,     s = 'moderate evidence for effect';
elseif BF10 > 1,     s = 'anecdotal evidence for effect';
elseif BF10 > 1/3,   s = 'anecdotal evidence for null';
elseif BF10 > 1/10,  s = 'moderate evidence for null';
elseif BF10 > 1/30,  s = 'strong evidence for null';
elseif BF10 > 1/100, s = 'very strong evidence for null';
else,                s = 'extreme evidence for null';
end
end
