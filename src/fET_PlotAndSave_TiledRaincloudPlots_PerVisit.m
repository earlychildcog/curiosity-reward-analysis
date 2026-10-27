function fig = fET_PlotAndSave_TiledRaincloudPlots_PerVisit(folderFigures, T, variable, conditions, visits, args, opts)

arguments
    folderFigures
    T
    variable 
    conditions
    visits
    args % Those are arguments for the fRaincloudPlot function
    opts.titleStr (1,:) cell {mustBeText}
    opts.resize_figure                     = [1,1]
    opts.transform (1,1) double            = 1
    opts.yLabel (1,:) cell {mustBeText}    = {}
end

fig=figure;
tiledlayout("horizontal");
args.labels =  cellstr(conditions);
args.make_new_figure = 0;
varargin = namedargs2cell(args);
for iVisit = 1:length(visits)
    visit  = visits{iVisit};
    currVars = [];
    for iConditions = 1:length(conditions)
        condition = conditions{iConditions};
        currVars = [currVars, T.(strcat(variable, '_', condition, '_', visit))];
    end
    currVars = currVars * opts.transform;
    nexttile
    util.fRaincloudPlot(currVars, varargin{:});
    yline(0,'--'); yline(100,'--');
    subtitle(strrep(visit,'_',': '))
    if iVisit == 1 && ~isempty(opts.yLabel)
        ylabel(opts.yLabel)
    end
end
pos=get(fig,"Position");
fig.Position = [pos(1) pos(2) pos(3)*opts.resize_figure(1) pos(4)*opts.resize_figure(2)];
if isempty(opts.titleStr); titleStr = variable; else; titleStr = opts.titleStr; end
sgtitle(titleStr);
fontsize(args.font_size,"points");
saveas(gcf, fullfile(folderFigures,sprintf("%s_PerCond_%s.png", variable,strjoin([visits{:}], "-"))));
print(gcf,fullfile(folderFigures,sprintf("%s_PerCond_%s", variable,strjoin([visits{:}], "-"))),'-dsvg');
% [h, p, ci, stats] = ttest(T.tBox2_afterB1_TestDiff, T.tBox2_afterB1_TestSame); disp(p);


end