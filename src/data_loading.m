function [order_seq, coll_t, bin_ctrs, n_bins, dyad_summ, interactions_tbl] = data_loading(baseFolder, itFolder, cfg)
%DATA_LOADING Load raw game/interaction logs and build the analysis
%   tables used throughout this project: per-order outcomes (order_seq),
%   binned collision rates (coll_t), per-dyad summaries (dyad_summ), and
%   the long table of individual resource interactions
%   (interactions_tbl, feeds collaboration_metrics.m).
[all_game_events, file_meta, nFiles] = load_game_events(baseFolder);

order_seq = build_order_sequence_table(all_game_events, file_meta, nFiles);
[coll_t, bin_ctrs, n_bins] = build_collision_table(all_game_events, file_meta, nFiles, cfg.bin_sz, cfg.max_time);
dyad_summ = build_dyad_summary(order_seq, coll_t);

interactions_tbl = load_player_interactions(itFolder);
end


function [all_game_events, file_meta, nFiles] = load_game_events(baseFolder)
%LOAD_GAME_EVENTS Read every game_events.jsonl under baseFolder.
%   Each session folder is expected to be named '<dyadID>_..._level_<N>...'
%   so the dyad ID and level can be parsed back out of the folder name.
F      = dir(fullfile(baseFolder,'**','game_events.jsonl'));
nFiles = numel(F);
fprintf('Found %d files\n', nFiles);

all_game_events = cell(nFiles,1);
file_meta       = cell(nFiles,1);

for k = 1:nFiles
    fid = fopen(fullfile(F(k).folder,F(k).name),'r');
    C   = textscan(fid,'%s','Delimiter','\n','Whitespace','');
    fclose(fid);
    if isempty(C{1}), continue; end
    try
        all_game_events{k} = cellfun(@jsondecode,C{1},'UniformOutput',false);
    catch
        all_game_events{k} = {};
    end

    [~,fn]     = fileparts(F(k).folder);
    sp         = split(fn,'_');
    dyad       = sp{1};
    li         = find(contains(sp,'level'),1);
    if ~isempty(li) && li < numel(sp)
        file_meta{k} = struct('dyad',dyad,'level',str2double(sp{li+1}));
    end
end
fprintf('Loading complete\n');
end


function order_seq = build_order_sequence_table(all_game_events, file_meta, nFiles)
%BUILD_ORDER_SEQUENCE_TABLE Per-order completion outcome and duration.
%   For each session, matches 'new_orders' events to their resolving
%   'completed_order'/'order_expired' event, keeping only orders that
%   were both created and resolved, ordered by creation time. Feeds
%   Models A and B.
order_seq = table();

for k = 1:nFiles
    if isempty(all_game_events{k}) || isempty(file_meta{k}), continue; end
    dyad  = file_meta{k}.dyad;
    level = file_meta{k}.level;
    E     = all_game_events{k};

    o_starts  = containers.Map('KeyType','char','ValueType','double');
    o_ends    = containers.Map('KeyType','char','ValueType','double');
    o_outcome = containers.Map('KeyType','char','ValueType','char');
    o_appear  = {};

    for i = 1:numel(E)
        if ~isstruct(E{i}) || ~isfield(E{i},'hook_ref'), continue; end
        t = parse_env_time(E{i}.env_time);
        switch E{i}.hook_ref
            case 'new_orders'
                if isfield(E{i},'new_orders') && isstruct(E{i}.new_orders)
                    o = E{i}.new_orders;
                    if isfield(o,'id') && ~isKey(o_starts,o.id)
                        if isfield(o,'start_time') && ischar(o.start_time)
                            o_starts(o.id) = parse_env_time(o.start_time);
                        else
                            o_starts(o.id) = t;
                        end
                        o_appear{end+1} = o.id;
                    end
                end
            case {'completed_order','order_expired'}
                if isfield(E{i},'order') && isstruct(E{i}.order) && isfield(E{i}.order,'id')
                    oid = E{i}.order.id;
                    o_ends(oid)    = t;
                    o_outcome(oid) = E{i}.hook_ref;
                end
        end
    end

    valid = {};
    for oi = 1:numel(o_appear)
        if isKey(o_ends,o_appear{oi}), valid{end+1} = o_appear{oi}; end
    end
    if numel(valid) < 2, continue; end

    ts = cellfun(@(id) o_starts(id), valid);
    [~,si] = sort(ts);
    valid  = valid(si);

    for oi = 1:numel(valid)
        id   = valid{oi};
        dur  = o_ends(id) - o_starts(id);
        obin = double(strcmp(o_outcome(id),'completed_order'));
        order_seq = [order_seq; table(string(dyad),double(level),double(oi),obin,dur,...
            'VariableNames',{'dyad','level','order_pos','outcome_bin','completion_time_s'})];
    end
end

order_seq.level = double(order_seq.level);
order_seq.dyad  = categorical(order_seq.dyad);
fprintf('Order table: %d rows\n', height(order_seq));
end


function [coll_t, bin_ctrs, n_bins] = build_collision_table(all_game_events, file_meta, nFiles, bin_sz, max_time)
%BUILD_COLLISION_TABLE Binned player-collision rate over game time.
%   Level 4 is excluded by design (no collision mechanic at that level).
%   Feeds Model C.
bins     = 0:bin_sz:max_time;
n_bins   = numel(bins)-1;
bin_ctrs = bins(1:end-1) + bin_sz/2;

coll_t = table();

for k = 1:nFiles
    if isempty(all_game_events{k}) || isempty(file_meta{k}), continue; end
    if file_meta{k}.level == 3, continue; end
    level = file_meta{k}.level;
    dyad  = file_meta{k}.dyad;
    E     = all_game_events{k};

    t0 = Inf;
    for i = 1:numel(E)
        if isstruct(E{i}) && isfield(E{i},'env_time')
            v = parse_env_time(E{i}.env_time);
            if ~isnan(v), t0 = v; break; end
        end
    end

    cr = [];
    for i = 1:numel(E)
        if isstruct(E{i}) && isfield(E{i},'hook_ref') && strcmp(E{i}.hook_ref,'players_collide')
            t = parse_env_time(E{i}.env_time) - t0;
            if t >= 0 && t <= max_time, cr(end+1) = t; end
        end
    end

    cnts = histcounts(cr, bins);
    for b = 1:n_bins
        coll_t = [coll_t; table(string(dyad),double(level),double(b),double(bin_ctrs(b)),...
            double(cnts(b)/bin_sz),...
            'VariableNames',{'dyad','level','time_bin','time_s','collision_rate'})];
    end
end

coll_t.level = double(coll_t.level);
coll_t.dyad  = categorical(coll_t.dyad);
end


function dyad_summ = build_dyad_summary(order_seq, coll_t)
%BUILD_DYAD_SUMMARY Per-dyad, per-level completion and collision rates.
%   Feeds Model D; extended with intertwinement/pattern-dynamics by
%   collaboration_metrics.m to feed Models E and F.
all_dyads = unique(order_seq.dyad);
dyad_summ = table();

for d = 1:numel(all_dyads)
    for lv = 0:3
        mo = order_seq.dyad==all_dyads(d) & order_seq.level==lv;
        if sum(mo) == 0, continue; end
        cr = mean(order_seq.outcome_bin(mo));

        if lv < 3
            mc = coll_t.dyad==all_dyads(d) & coll_t.level==lv;
            if sum(mc)==0, continue; end
            mc_val = mean(coll_t.collision_rate(mc));
        else
            mc_val = NaN;
        end

        dyad_summ = [dyad_summ; table(all_dyads(d),double(lv),cr,mc_val,...
            'VariableNames',{'dyad','level','comp_rate','mean_coll_rate'})];
    end
end
end


function interactions_tbl = load_player_interactions(itFolder)
%LOAD_PLAYER_INTERACTIONS Read every player_interactions_<dyad>, Level
%   <N>.json file under itFolder into a long table of individual
%   resource-interaction events (one row per non-released event).
%   Expects: {"<resource key>": [["<player: '0'|'1'|'-'>", "<timestamp>"], ...], ...}
%   where '-' marks the resource as released/unattended and is dropped
%   (it carries no player attribution, so it is not an "action by a
%   partner" for the fluidity/intertwinement formulas in
%   collaboration_metrics.m). Filenames are 1-indexed ('Level 1'..
%   'Level 4'); level is stored 0-indexed to match the rest of this
%   project.
F = dir(fullfile(itFolder,'player_interactions_*.json'));
fprintf('Found %d player_interactions files\n', numel(F));

interactions_tbl = table();

for k = 1:numel(F)
    tok = regexp(F(k).name, '^player_interactions_(.+), Level (\d+)\.json$', 'tokens', 'once');
    if isempty(tok), continue; end
    dyad  = tok{1};
    level = str2double(tok{2}) - 1;

    raw = fileread(fullfile(F(k).folder, F(k).name));
    S   = jsondecode(raw);
    fn  = fieldnames(S);

    for r = 1:numel(fn)
        rows = normalize_interaction_list(S.(fn{r}));
        for i = 1:numel(rows)
            player_str = rows{i}{1};
            if strcmp(player_str,'-'), continue; end
            t_s = parse_env_time(rows{i}{2});
            interactions_tbl = [interactions_tbl; table(string(dyad), level, string(fn{r}), string(player_str), t_s, ...
                'VariableNames',{'dyad','level','resource','player','t_s'})];
        end
    end
end

if height(interactions_tbl) > 0
    interactions_tbl.dyad = categorical(interactions_tbl.dyad);
end
fprintf('Interaction events table: %d rows\n', height(interactions_tbl));
end


function rows = normalize_interaction_list(raw)
%NORMALIZE_INTERACTION_LIST Coerce a decoded JSON interaction list into
%   an Nx1 cell array of {player_char, timestamp_char} pairs. jsondecode
%   unwraps a singleton JSON array to a bare pair instead of a 1-element
%   cell of pairs, so a single-interaction resource needs re-wrapping.
if iscell(raw) && numel(raw)==2 && ischar(raw{1}) && ischar(raw{2})
    rows = {raw};
else
    rows = raw(:);
end
end
