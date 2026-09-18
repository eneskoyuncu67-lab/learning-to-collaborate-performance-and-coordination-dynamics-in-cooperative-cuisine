function s = conditional_pstr(p)
%CONDITIONAL_PSTR Format a p-value, flooring tiny values to 'p < .001'.
if p < 0.001, s = 'p < .001';
else,         s = sprintf('p = %.3f',p); end
end
