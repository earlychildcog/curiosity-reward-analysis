function fig = fET_PlotAndSave_Boxplots(folderFigures, T, variable, condition, visits, args, opts)

arguments
    folderFigures
    T
    variable
    condition
    visits
    args
    opts.y_line        = []
    opts.transform     = 1
    opts.titleCell     = {}
    opts.yLabel        = {}
    opts.resize_figure = [1,1]
end

args.labels  = cellstr(visits);
args.y_label = opts.yLabel;
varargin     = namedargs2cell(args);
variables = [];
for visit = visits
    variables = [variables, T.(variable + "_" + condition + "_" + visit{:})];
end
fig = figure;
if ~isempty(opts.y_line)
    for iLine = opts.y_line
        yline(iLine,'--');
    end
end
util.fBoxplotWithDotsAndColors(variables * opts.transform, varargin{:});
title(opts.titleCell);
pos=get(fig,"Position");
fig.Position = [pos(1) pos(2) pos(3)*opts.resize_figure(1) pos(4)*opts.resize_figure(2)];
saveas(gcf, fullfile(folderFigures, sprintf("%s_%s_PerVisit.png", variable, condition)));
print(gcf, fullfile(folderFigures, sprintf("%s_%s_PerVisit", variable, condition)),'-dsvg');

end
