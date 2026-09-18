function print_sample_size_report(order_seq, coll_t, dyad_summ, it_session, lv_names)
%PRINT_SAMPLE_SIZE_REPORT N/n breakdown per level for each model.
fprintf('\n============================================================\n');
fprintf('SAMPLE SIZE REPORT\n');
fprintf('============================================================\n');

fprintf('\nModel A: outcome_bin ~ order_pos + (1|dyad)\n');
fprintf('%-10s %-15s %-10s\n','Level','N (orders)','n (dyads)');
for lv = 0:3
    T = order_seq(order_seq.level==lv,:);
    fprintf('%-10s %-15d %-10d\n', lv_names{lv+1}, height(T), numel(unique(T.dyad)));
end

fprintf('\nModel B: completion_time_s ~ order_pos + (1|dyad) [completed only]\n');
fprintf('%-10s %-15s %-10s\n','Level','N (orders)','n (dyads)');
for lv = 0:3
    T = order_seq(order_seq.level==lv & order_seq.outcome_bin==1,:);
    fprintf('%-10s %-15d %-10d\n', lv_names{lv+1}, height(T), numel(unique(T.dyad)));
end

fprintf('\nModel C: collision_rate ~ time_bin + (1|dyad) [Levels 1-3 only]\n');
fprintf('%-10s %-15s %-10s\n','Level','N (obs)','n (dyads)');
for lv = 0:2
    T = coll_t(coll_t.level==lv,:);
    fprintf('%-10s %-15d %-10d\n', lv_names{lv+1}, height(T), numel(unique(T.dyad)));
end

fprintf('\nModel D: comp_rate ~ mean_coll_rate [dyad-level OLS]\n');
fprintf('%-10s %-10s\n','Level','n (dyads)');
for lv = 0:2
    T = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.mean_coll_rate),:);
    fprintf('%-10s %-10d\n', lv_names{lv+1}, height(T));
end

fprintf('\nModel E: comp_rate ~ intertwinement [dyad-level OLS]\n');
fprintf('%-10s %-10s\n','Level','n (dyads)');
for lv = 0:3
    T = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.intertwinement),:);
    fprintf('%-10s %-10d\n', lv_names{lv+1}, height(T));
end

fprintf('\nModel F: comp_rate ~ pd [dyad-level OLS]\n');
fprintf('%-10s %-10s\n','Level','n (dyads)');
for lv = 0:3
    T = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.pd),:);
    fprintf('%-10s %-10d\n', lv_names{lv+1}, height(T));
end

fprintf('\nModel G: intertwinement ~ level + (1|dyad) [pooled across levels]\n');
fprintf('N (dyad x level observations) = %d, n (dyads) = %d\n', ...
    height(it_session), numel(unique(it_session.dyad)));
end
