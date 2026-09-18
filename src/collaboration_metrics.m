function [it_session, fluidity_tbl, pd_tbl, dyad_summ] = collaboration_metrics(interactions_tbl, dyad_summ)
%COLLABORATION_METRICS Compute intertwinement, fluidity, and pattern
%   dynamics (Schroder, Heinrich & Kopp, 2025, Eq. 1-3) from the raw
%   interaction log, and merge intertwinement/pattern-dynamics onto the
%   dyad-level summary table (feeds Models E-G).
it_session   = build_session_intertwinement(interactions_tbl);
fluidity_tbl = build_unit_fluidity(interactions_tbl);
pd_tbl       = build_pattern_dynamics(fluidity_tbl);
dyad_summ    = add_collab_metrics(dyad_summ, it_session, pd_tbl);
end


function it_session = build_session_intertwinement(interactions_tbl)
%BUILD_SESSION_INTERTWINEMENT Resource-based intertwinement score per
%   dyad x level (Eq. 1): it = mean over resources of
%   2*min(share_p0, share_p1), where share_p is the fraction of that
%   resource's interactions performed by player p. it = 1 for a
%   perfectly balanced 50/50 split on every resource used; it = 0 if
%   one player did everything alone. Computed exactly as in Schroder
%   et al. (2025) with T = resources, matching their Figure 5.
it_session = table();
if isempty(interactions_tbl)
    return;
end

dyads = unique(interactions_tbl.dyad);
for d = 1:numel(dyads)
    for lv = 0:3
        T = interactions_tbl(interactions_tbl.dyad==dyads(d) & interactions_tbl.level==lv,:);
        if isempty(T), continue; end

        res  = unique(T.resource);
        it_r = nan(numel(res),1);
        for r = 1:numel(res)
            Tr      = T(T.resource==res(r),:);
            f0      = mean(Tr.player=="0");
            f1      = mean(Tr.player=="1");
            it_r(r) = 2*min(f0,f1);
        end

        it_session = [it_session; table(dyads(d), lv, mean(it_r), numel(res), ...
            'VariableNames',{'dyad','level','intertwinement','n_resources'})];
    end
end
end


function fluidity_tbl = build_unit_fluidity(interactions_tbl)
%BUILD_UNIT_FLUIDITY Fluidity of unit assignment per dyad x level x
%   resource (Eq. 2): Fu = Tu / (n-1), where Su is the time-ordered
%   sequence of players who interacted with the unit (released '-'
%   states already excluded on load) and Tu counts adjacent player
%   changes in that sequence (Su_i ~= Su_i+1). Undefined (NaN) for
%   units touched by fewer than 2 actions.
fluidity_tbl = table();
if isempty(interactions_tbl)
    return;
end

dyads = unique(interactions_tbl.dyad);
for d = 1:numel(dyads)
    for lv = 0:3
        T = interactions_tbl(interactions_tbl.dyad==dyads(d) & interactions_tbl.level==lv,:);
        if isempty(T), continue; end

        res = unique(T.resource);
        for r = 1:numel(res)
            Tr = sortrows(T(T.resource==res(r),:), 't_s');
            n  = height(Tr);
            if n < 2
                Fu = NaN;
            else
                Su = Tr.player;
                Tu = sum(Su(1:end-1) ~= Su(2:end));
                Fu = Tu / (n-1);
            end
            fluidity_tbl = [fluidity_tbl; table(dyads(d), lv, res(r), n, Fu, ...
                'VariableNames',{'dyad','level','resource','n_interactions','Fu'})];
        end
    end
end
end


function pd_tbl = build_pattern_dynamics(fluidity_tbl)
%BUILD_PATTERN_DYNAMICS Pattern dynamics score per dyad x level (Eq. 3):
%   pd = min over collaboration patterns phi of the mean fluidity of
%   units within phi. This data supports only a SINGLE GLOBAL PATTERN
%   (all resource units used in that dyad x level, since no task/
%   subtask-to-unit grouping is available), so pd here is the plain
%   mean Fu across all units for that dyad x level -- see the
%   pattern-dynamics caveat in dyadic_learning_analysis.m before
%   comparing directly to the paper's multi-pattern figures.
pd_tbl = table();
if isempty(fluidity_tbl)
    return;
end

[grp, dyad_id, level_id] = findgroups(fluidity_tbl.dyad, fluidity_tbl.level);
for g = 1:max(grp)
    idx = grp==g;
    pd  = mean(fluidity_tbl.Fu(idx), 'omitnan');
    n_u = sum(~isnan(fluidity_tbl.Fu(idx)));
    pd_tbl = [pd_tbl; table(dyad_id(g), level_id(g), pd, n_u, ...
        'VariableNames',{'dyad','level','pd','n_units'})];
end
end


function dyad_summ = add_collab_metrics(dyad_summ, it_session, pd_tbl)
%ADD_COLLAB_METRICS Left-join intertwinement and pattern-dynamics scores
%   onto the dyad-level summary table, by dyad x level. Feeds Models E
%   and F.
dyad_summ.intertwinement = nan(height(dyad_summ),1);
dyad_summ.pd             = nan(height(dyad_summ),1);

for i = 1:height(dyad_summ)
    mi = it_session.dyad==dyad_summ.dyad(i) & it_session.level==dyad_summ.level(i);
    if any(mi)
        idx = find(mi,1);
        dyad_summ.intertwinement(i) = it_session.intertwinement(idx);
    end

    mp = pd_tbl.dyad==dyad_summ.dyad(i) & pd_tbl.level==dyad_summ.level(i);
    if any(mp)
        idx = find(mp,1);
        dyad_summ.pd(i) = pd_tbl.pd(idx);
    end
end
end
