function make_all_figures(order_seq, coll_t, dyad_summ, it_session, pd_tbl, fluidity_tbl, ...
    res, bin_ctrs, n_bins, cfg, saving_figures, figuredir)
%MAKE_ALL_FIGURES Draws and (optionally) saves all 6 figures for this
%   project. res is a struct bundling the model outputs needed for
%   plotting (see dyadic_learning_analysis.m for how it is assembled):
%   glme_lv, b_A, p_A, lme_ct, b_B, p_B, r2_B_lv, lme_coll, b_C, p_C,
%   r2_C, b_D, p_D, r2_D.
make_figure1(order_seq, res.glme_lv, res.b_A, res.p_A, res.lme_ct, res.b_B, res.p_B, res.r2_B_lv, ...
    cfg, saving_figures, figuredir);

make_figure2(coll_t, res.lme_coll, res.b_C, res.p_C, res.r2_C, dyad_summ, res.b_D, res.p_D, res.r2_D, ...
    bin_ctrs, n_bins, cfg, saving_figures, figuredir);

make_figure3(order_seq, coll_t, cfg, saving_figures, figuredir);
make_figure4(it_session, cfg, saving_figures, figuredir);
make_figure5(pd_tbl, cfg, saving_figures, figuredir);
make_figure6(fluidity_tbl, cfg, saving_figures, figuredir);
end


function make_figure1(order_seq, glme_lv, b_A, p_A, lme_ct, b_B, p_B, r2_B_lv, cfg, saving_figures, figuredir)
%MAKE_FIGURE1 Panel A: completion probability vs. order position (per level).
%             Panel B: completion time vs. order position (per level).
f1 = figure(1);
set(f1,'Units','normalized','OuterPosition',[0 0 1 1]);

L     = [0.07 0.30 0.53 0.76];
PW    = 0.19;
PH    = 0.35;
rowA  = 0.57;
rowB  = 0.09;

for lv = 0:3
    col = cfg.lv_col(lv+1,:);

    ax = axes('Position',[L(lv+1), rowA, PW, PH]); %#ok<LAXES>
    hold on; grid on;

    T    = order_seq(order_seq.level==lv,:);
    dys  = unique(T.dyad);
    mxp  = max(T.order_pos);

    for d = 1:numel(dys)
        Td = sortrows(T(T.dyad==dys(d),:),'order_pos');
        if height(Td) < 3, continue; end
        ysm = movmean(double(Td.outcome_bin),3);
        plot(Td.order_pos, ysm,'Color',[col cfg.alpha_d],'LineWidth',cfg.lw_dyad);
    end

    [bm, bse, ~, vp] = group_stats(T.order_pos, double(T.outcome_bin), mxp);
    if numel(vp)>1
        fill([vp; flipud(vp)],[bm(vp)+bse(vp); flipud(bm(vp)-bse(vp))],...
            col,'FaceAlpha',cfg.alpha_s,'EdgeColor','none');
        plot(vp, bm(vp),'Color',col,'LineWidth',cfg.lw_mean,...
            'Marker','o','MarkerSize',cfg.ms,'MarkerFaceColor',col);
    end

    int_g = glme_lv{lv+1}.Coefficients.Estimate(1);
    xf    = linspace(1,mxp,100);
    yf    = 1./(1+exp(-(int_g + b_A(lv+1)*xf)));
    plot(xf, yf,'--','Color',col*0.55,'LineWidth',cfg.lw_mean);

    yline(0.5,':','Color',[0.5 0.5 0.5],'LineWidth',1.5);

    ylim([0 1.05]);
    yticks([0 0.5 1]); yticklabels({'0','0.5','1'});
    xlim([0.5 mxp+0.5]);
    set(gca,'FontSize',cfg.fs,'Box','off','TickDir','out');
    xlabel('Order position','FontSize',cfg.fs);
    if lv==0, ylabel('P(completed)','FontSize',cfg.fs); end
    title(cfg.lv_names{lv+1},'FontSize',cfg.fs,'FontWeight','bold','Color',col);

    text(0.97,0.05,...
        {sprintf('\\beta=%.3f',b_A(lv+1));...
         sprintf('OR=%.3f',exp(b_A(lv+1)));...
         conditional_pstr(p_A(lv+1))},...
        'Units','normalized','HorizontalAlignment','right',...
        'VerticalAlignment','bottom','FontSize',cfg.fs-4);

    if lv==0
        annotation('textbox',...
            [L(1)-0.04, rowA+PH+0.02, 0.04, 0.04],...
            'String','A','LineStyle','none',...
            'FontSize',cfg.fs_ann,'FontWeight','bold');
    end

    ax2 = axes('Position',[L(lv+1), rowB, PW, PH]); %#ok<LAXES>
    hold on; grid on;

    Tc  = order_seq(order_seq.level==lv & order_seq.outcome_bin==1,:);
    mxc = max(Tc.order_pos);

    scatter(Tc.order_pos, Tc.completion_time_s,...
        8, col,'filled','MarkerFaceAlpha',0.25);

    [bmc, bsec, ~, vpc] = group_stats(Tc.order_pos, Tc.completion_time_s, mxc);
    if numel(vpc)>1
        fill([vpc; flipud(vpc)],[bmc(vpc)+bsec(vpc); flipud(bmc(vpc)-bsec(vpc))],...
            col,'FaceAlpha',cfg.alpha_s,'EdgeColor','none');
        plot(vpc, bmc(vpc),'Color',col,'LineWidth',cfg.lw_mean,...
            'Marker','o','MarkerSize',cfg.ms,'MarkerFaceColor',col);
    end

    if ~isnan(b_B(lv+1))
        int_c = lme_ct{lv+1}.Coefficients.Estimate(1);
        xfc   = linspace(1,mxc,100);
        yfc   = int_c + b_B(lv+1)*xfc;
        plot(xfc, yfc,'--','Color',col*0.55,'LineWidth',cfg.lw_mean);

        text(0.97,0.97,...
            {sprintf('\\beta=%.2fs',b_B(lv+1));...
             conditional_pstr(p_B(lv+1));...
             sprintf('R^2=%.3f',r2_B_lv(lv+1))},...
            'Units','normalized','HorizontalAlignment','right',...
            'VerticalAlignment','top','FontSize',cfg.fs-4);
    end

    xlim([0.5 mxc+0.5]);
    set(gca,'FontSize',cfg.fs,'Box','off','TickDir','out');
    xlabel('Order position','FontSize',cfg.fs);
    if lv==0, ylabel('Completion time (s)','FontSize',cfg.fs); end

    if lv==0
        annotation('textbox',...
            [L(1)-0.04, rowB+PH+0.02, 0.04, 0.04],...
            'String','B','LineStyle','none',...
            'FontSize',cfg.fs_ann,'FontWeight','bold');
    end
end

if saving_figures
    snamef = sprintf('%s/fig1_learning_and_completion.png', figuredir);
    print(f1,'-dpng','-r400',snamef);
    fprintf('Saved fig1_learning_and_completion\n');
end
end


function make_figure2(coll_t, lme_coll, b_C, p_C, r2_C, dyad_summ, b_D, p_D, r2_D, bin_ctrs, n_bins, cfg, saving_figures, figuredir)
%MAKE_FIGURE2 Panel A: collision rate vs. game time (per level, levels 1-3).
%             Panel B: dyad completion rate vs. mean collision rate (levels 1-3).
f2 = figure(2);
set(f2,'Units','normalized','OuterPosition',[0 0 1 1]);

L3   = [0.09 0.39 0.69];
PW3  = 0.24;
PH   = 0.35;
rowA = 0.57;
rowB = 0.09;

for lv = 0:2
    col = cfg.lv_col(lv+1,:);

    ax3 = axes('Position',[L3(lv+1), rowA, PW3, PH]); %#ok<LAXES>
    hold on; grid on;

    Tc2 = coll_t(coll_t.level==lv,:);

    scatter(Tc2.time_s, Tc2.collision_rate,...
        8, col,'filled','MarkerFaceAlpha',0.20);

    gm = nan(n_bins,1); gse = nan(n_bins,1);
    for b = 1:n_bins
        v = Tc2.collision_rate(Tc2.time_bin==b);
        if numel(v)>=2
            gm(b)  = mean(v);
            gse(b) = std(v)/sqrt(numel(v));
        end
    end
    vb = find(~isnan(gm));
    if numel(vb)>1
        fill([bin_ctrs(vb), fliplr(bin_ctrs(vb))],...
             [gm(vb)'+gse(vb)', fliplr(gm(vb)'-gse(vb)')],...
             col,'FaceAlpha',cfg.alpha_s,'EdgeColor','none');
        plot(bin_ctrs(vb), gm(vb),'Color',col,'LineWidth',cfg.lw_mean,...
            'Marker','o','MarkerSize',cfg.ms,'MarkerFaceColor',col);
    end

    int_cc = lme_coll{lv+1}.Coefficients.Estimate(1);
    xcc    = bin_ctrs;
    ycc    = int_cc + b_C(lv+1)*(1:n_bins);
    plot(xcc, ycc,'--','Color',col*0.55,'LineWidth',cfg.lw_mean);

    xline(150,':','Color',[0.5 0.5 0.5],'LineWidth',1.5);
    xlim([5 cfg.max_time]);

    text(0.97,0.97,...
        {sprintf('\\beta=%.5f',b_C(lv+1));...
         conditional_pstr(p_C(lv+1));...
         sprintf('R^2=%.3f',r2_C(lv+1))},...
        'Units','normalized','HorizontalAlignment','right',...
        'VerticalAlignment','top','FontSize',cfg.fs-4);

    set(gca,'FontSize',cfg.fs,'Box','off','TickDir','out');
    xlabel('Game time (s)','FontSize',cfg.fs);
    if lv==0, ylabel('Collision rate (coll/s)','FontSize',cfg.fs); end
    title(cfg.lv_names{lv+1},'FontSize',cfg.fs,'FontWeight','bold','Color',col);

    if lv==0
        annotation('textbox',...
            [L3(1)-0.05, rowA+PH+0.02, 0.04, 0.04],...
            'String','A','LineStyle','none',...
            'FontSize',cfg.fs_ann,'FontWeight','bold');
    end

    ax4 = axes('Position',[L3(lv+1), rowB, PW3, PH]); %#ok<LAXES>
    hold on; grid on;

    Td2 = dyad_summ(dyad_summ.level==lv & ~isnan(dyad_summ.mean_coll_rate),:);

    if height(Td2) >= 4
        scatter(Td2.mean_coll_rate, Td2.comp_rate,...
            80, col,'filled','MarkerFaceAlpha',0.80);

        xr  = linspace(min(Td2.mean_coll_rate), max(Td2.mean_coll_rate), 50);
        cf  = polyfit(Td2.mean_coll_rate, Td2.comp_rate, 1);
        yr  = polyval(cf, xr);
        plot(xr, yr,'--','Color',col*0.55,'LineWidth',cfg.lw_mean);

        text(0.97,0.97,...
            {sprintf('\\beta=%.3f', b_D(lv+1));...
             conditional_pstr(p_D(lv+1));...
             sprintf('R^2=%.3f', r2_D(lv+1))},...
            'Units','normalized','HorizontalAlignment','right',...
            'VerticalAlignment','top','FontSize',cfg.fs-4);
    end

    set(gca,'FontSize',cfg.fs,'Box','off','TickDir','out');
    xlabel('Mean collision rate (coll/s)','FontSize',cfg.fs);
    if lv==0, ylabel('Completion rate','FontSize',cfg.fs); end

    if lv==0
        annotation('textbox',...
            [L3(1)-0.05, rowB+PH+0.02, 0.04, 0.04],...
            'String','B','LineStyle','none',...
            'FontSize',cfg.fs_ann,'FontWeight','bold');
    end
end

if saving_figures
    snamef = sprintf('%s/fig2_collision_analysis.png', figuredir);
    print(f2,'-dpng','-r400',snamef);
    fprintf('Saved fig2_collision_analysis\n');
end
end


function make_figure3(order_seq, coll_t, cfg, saving_figures, figuredir)
%MAKE_FIGURE3 Distributions of completion time (top row) and collision
%   rate (bottom row) per level, to accompany the descriptive table.
f3 = figure(3);
set(f3,'Units','normalized','OuterPosition',[0 0 1 1]);

for lv = 0:3
    col = cfg.lv_col(lv+1,:);

    subplot(2,4,lv+1);
    Tc = order_seq(order_seq.level==lv & order_seq.outcome_bin==1,:);
    histogram(Tc.completion_time_s,'FaceColor',col,'FaceAlpha',0.7,'Normalization','pdf');
    title(cfg.lv_names{lv+1},'FontSize',cfg.fs-2,'FontWeight','bold','Color',col);
    xlabel('Completion time (s)','FontSize',cfg.fs-4);
    if lv==0, ylabel('Density','FontSize',cfg.fs-4); end
    set(gca,'FontSize',cfg.fs-6,'Box','off','TickDir','out');

    subplot(2,4,lv+5);
    if lv < 3
        Tcol = coll_t(coll_t.level==lv,:);
        histogram(Tcol.collision_rate,'FaceColor',col,'FaceAlpha',0.7,'Normalization','pdf');
        xlabel('Collision rate (coll/s)','FontSize',cfg.fs-4);
        if lv==0, ylabel('Density','FontSize',cfg.fs-4); end
        set(gca,'FontSize',cfg.fs-6,'Box','off','TickDir','out');
    else
        axis off;
        text(0.5,0.5,'N/A (no collisions by design)','HorizontalAlignment','center','FontSize',cfg.fs-6);
    end
end

if saving_figures
    snamef = sprintf('%s/fig3_distributions.png', figuredir);
    print(f3,'-dpng','-r400',snamef);
    fprintf('Saved fig3_distributions\n');
end
end


function make_figure4(it_session, cfg, saving_figures, figuredir)
%MAKE_FIGURE4 Session-level intertwinement score by kitchen layout
%   (jittered dots per dyad + group mean), matching the style of the
%   paper's Figure 5 center panel.
f4 = figure(4);
set(f4,'Units','normalized','OuterPosition',[0.15 0.2 0.5 0.5]);
hold on; grid on;

for lv = 0:3
    col = cfg.lv_col(lv+1,:);
    v   = it_session.intertwinement(it_session.level==lv);
    if isempty(v), continue; end
    x = (lv+1) + (rand(numel(v),1)-0.5)*0.15;
    scatter(x, v, 40, col, 'filled', 'MarkerFaceAlpha', 0.6);
    plot([lv+0.7 lv+1.3], [mean(v) mean(v)], 'k-', 'LineWidth', 2.5);
end

set(gca,'XTick',1:4,'XTickLabel',cfg.lv_names,'FontSize',cfg.fs,'Box','off','TickDir','out');
ylabel('Intertwinement score','FontSize',cfg.fs);
ylim([0 1]);
title('Session-level intertwinement by kitchen layout','FontSize',cfg.fs-2,'FontWeight','bold');

if saving_figures
    snamef = sprintf('%s/fig4_intertwinement_by_level.png', figuredir);
    print(f4,'-dpng','-r400',snamef);
    fprintf('Saved fig4_intertwinement_by_level\n');
end
end


function make_figure5(pd_tbl, cfg, saving_figures, figuredir)
%MAKE_FIGURE5 Pattern dynamics score by kitchen layout (jittered dots
%   per dyad + group mean), matching the style of make_figure4.
f5 = figure(5);
set(f5,'Units','normalized','OuterPosition',[0.15 0.2 0.5 0.5]);
hold on; grid on;

for lv = 0:3
    col = cfg.lv_col(lv+1,:);
    v   = pd_tbl.pd(pd_tbl.level==lv & ~isnan(pd_tbl.pd));
    if isempty(v), continue; end
    x = (lv+1) + (rand(numel(v),1)-0.5)*0.15;
    scatter(x, v, 40, col, 'filled', 'MarkerFaceAlpha', 0.6);
    plot([lv+0.7 lv+1.3], [mean(v) mean(v)], 'k-', 'LineWidth', 2.5);
end

set(gca,'XTick',1:4,'XTickLabel',cfg.lv_names,'FontSize',cfg.fs,'Box','off','TickDir','out');
ylabel('Pattern dynamics score','FontSize',cfg.fs);
title('Pattern dynamics by kitchen layout','FontSize',cfg.fs-2,'FontWeight','bold');

if saving_figures
    snamef = sprintf('%s/fig5_pattern_dynamics_by_level.png', figuredir);
    print(f5,'-dpng','-r400',snamef);
    fprintf('Saved fig5_pattern_dynamics_by_level\n');
end
end


function make_figure6(fluidity_tbl, cfg, saving_figures, figuredir)
%MAKE_FIGURE6 Distribution of per-unit fluidity (Fu) scores, per level.
f6 = figure(6);
set(f6,'Units','normalized','OuterPosition',[0 0.15 1 0.5]);

for lv = 0:3
    col = cfg.lv_col(lv+1,:);
    subplot(1,4,lv+1);
    v = fluidity_tbl.Fu(fluidity_tbl.level==lv & ~isnan(fluidity_tbl.Fu));
    if ~isempty(v)
        histogram(v,'FaceColor',col,'FaceAlpha',0.7,'Normalization','pdf');
    end
    title(cfg.lv_names{lv+1},'FontSize',cfg.fs-2,'FontWeight','bold','Color',col);
    xlabel('Fluidity (F_u)','FontSize',cfg.fs-4);
    if lv==0, ylabel('Density','FontSize',cfg.fs-4); end
    set(gca,'FontSize',cfg.fs-6,'Box','off','TickDir','out');
end

if saving_figures
    snamef = sprintf('%s/fig6_fluidity_distributions.png', figuredir);
    print(f6,'-dpng','-r400',snamef);
    fprintf('Saved fig6_fluidity_distributions\n');
end
end
