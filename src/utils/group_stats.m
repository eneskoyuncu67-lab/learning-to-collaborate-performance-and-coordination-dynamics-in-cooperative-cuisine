function [bm, bse, bn, vp] = group_stats(x, y, mx)
%GROUP_STATS Mean/SE/N of y at each integer value of x in 1:mx.
%   vp indexes the values of x with at least 2 observations.
bm  = nan(mx,1); bse = nan(mx,1); bn = zeros(mx,1);
for p = 1:mx
    v = y(x==p);
    if numel(v)>=2
        bm(p)  = mean(v,'omitnan');
        bse(p) = std(v,'omitnan')/sqrt(numel(v));
        bn(p)  = numel(v);
    end
end
vp = find(bn>=2);
end
