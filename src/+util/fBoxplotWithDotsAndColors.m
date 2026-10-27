% Boxplot, but more sophisticated:
%  - Add data points over box
%  - Colourful plot (includinc face of box)
%  - Re-coloured outliers in grey instead of red
%  - Keeps empty datasets in the plot with their labels
%
% Use: hBoxplot = fBoxplotWithDotsAndColors(data,[colours],[labels],varargin)
% INPUT:
%  - data:      organised in columns (several columns for several boxplots)
%               or in cells of a cell array (one cell per boxplot)
%               add NaNs if needed for different sized datasets.
%  - colours:   [OPTIONAL] RGB triplets organised by lines, as many lines as data
%               columns/cells. If not provided, MATLAB default colors will be used.
%  - labels:    [OPTIONAL] cell of strings, as many strings as data columns/cells.
%               If not provided, numerical labels (1,2,...) will be used.
% Optional inputs (name-value pairs):
%  - plotLines: whether to plot grey lines linking participants' data (default: 1)
%  - plotLabels: whether to display labels (default: 1)
%  - positions: custom positions for the boxes (default: [])
%  - Plus all optional inputs from fScatterWithReg
%
% OUTPUT:
%  - hBoxplot:  handle of the boxplot, can be replaced by ~ if not useful
%               to keep.
%
% Careful about having the same dimensions for all input and about giving
% it in the same order each time (e.g. if 2 boxes, one for each group,
% also give 2 colours and labels, in the same order as in data).
%

function hBoxplot = fBoxplotWithDotsAndColors(data, varargin)

%% check all the inputs and if they do not exist then revert to default settings
% input parsing settings
p = inputParser;
p.CaseSensitive = true;
p.Parameters;
p.Results;
p.KeepUnmatched = true;
validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);

% Define default MATLAB colors for multiple datasets
defaultColors = [
    0 0.4470 0.7410;      % blue
    0.8500 0.3250 0.0980; % orange
    0.9290 0.6940 0.1250; % yellow
    0.4940 0.1840 0.5560; % purple
    0.4660 0.6740 0.1880; % green
    0.3010 0.7450 0.9330; % cyan
    0.6350 0.0780 0.1840; % burgundy
    ];

% set the required input arguments
addRequired(p, 'data');

% Optional inputs with defaults
addParameter(p, 'colors', [], @(x) isnumeric(x));
addParameter(p, 'labels', {}, @(x) isempty(x) || iscell(x));
addParameter(p, 'plotLines', 1, @isnumeric);
addParameter(p, 'plotLabels', 1, @isnumeric);
addParameter(p, 'positions', [], @isnumeric);
addParameter(p, 'x_label', {''}, @iscellstr);
addParameter(p, 'y_label', {''}, @iscellstr);
addParameter(p, 'title_text', {''}, @iscellstr);
addParameter(p, 'x_lim', [], @isnumeric);
addParameter(p, 'y_lim', [], @isnumeric);
addParameter(p, 'point_size', 50, @isnumeric);
addParameter(p, 'font_size', 18, @isnumeric);
addParameter(p, 'line_width', 3, validScalarPosNum);
addParameter(p, 'alpha_points', .7, @isnumeric);
addParameter(p, 'axisSquare', 0, @isnumeric);
addParameter(p, 'alpha_lines', .2, @isnumeric);
addParameter(p, 'blackBox', false, @islogical);
addParameter(p, 'density_height', [], @(x) isnumeric(x));


% parse the input
parse(p, data, varargin{:});

% then set/get all the inputs out of this structure
data                = p.Results.data;
colors              = p.Results.colors;
labels              = p.Results.labels;
plotLines           = p.Results.plotLines;
plotLabels          = p.Results.plotLabels;
position            = p.Results.positions;
y_label             = p.Results.y_label;
x_label             = p.Results.x_label;
title_text          = p.Results.title_text;
x_lim               = p.Results.x_lim;
y_lim               = p.Results.y_lim;
point_size          = p.Results.point_size;
font_size           = p.Results.font_size;
line_width          = p.Results.line_width;
alpha_points        = p.Results.alpha_points;
axisSquare          = p.Results.axisSquare;
alpha_lines         = p.Results.alpha_lines;
blackBox            = p.Results.blackBox;
density_height      = p.Results.density_height;


% Prepare data - handle cell arrays or matrices and get the number of datasets
if iscell(data)
    % Handle cell array input
    nDatasets = length(data);
    
    % Get maximum length of data across all cells
    maxLength = 0;
    for i = 1:nDatasets
        if ~isempty(data{i}) && numel(data{i}) > 0 && ~all(isnan(data{i}(:)))
            maxLength = max(maxLength, length(data{i}(:)));
        end
    end
    
    % Default maxLength if all datasets are empty
    if maxLength == 0
        maxLength = 1;
    end
    
    % Convert to matrix format with NaNs for missing or empty values
    matrixData = nan(maxLength, nDatasets);
    for i = 1:nDatasets
        if ~isempty(data{i}) && numel(data{i}) > 0
            currentData = data{i}(:);
            matrixData(1:length(currentData), i) = currentData;
        end
    end
    dataMatrix = matrixData;
    
else
    % Handle matrix input - each column is a dataset
    [~, nDatasets] = size(data);
    dataMatrix = data;
end

% Identify empty datasets
emptyDatasets = false(1, nDatasets);
for i = 1:nDatasets
    emptyDatasets(i) = all(isnan(dataMatrix(:, i)));
end

% Generate default colors if not provided or expand if needed
% Count non-empty datasets for color assignment
nonEmptyDatasets = sum(~emptyDatasets);

if isempty(colors)
    if exist('linspecer','file')==2
        allColors = linspecer(nonEmptyDatasets);
    else
        % Use default MATLAB colors
        allColors = repmat(defaultColors, ceil(nonEmptyDatasets/size(defaultColors, 1)), 1);
        allColors = allColors(1:nonEmptyDatasets, :);
    end
    
    % Assign colors to datasets (empty datasets get a default gray color)
    colors = zeros(nDatasets, 3);
    nonEmptyCounter = 1;
    for i = 1:nDatasets
        if emptyDatasets(i)
            colors(i, :) = [0.8 0.8 0.8]; % Gray for empty datasets
        else
            colors(i, :) = allColors(nonEmptyCounter, :);
            nonEmptyCounter = nonEmptyCounter + 1;
        end
    end
elseif size(colors, 1) == 1 && nDatasets > 1
    % Replicate the single color for all non-empty boxes
    originalColor = colors;
    colors = zeros(nDatasets, 3);
    for i = 1:nDatasets
        if emptyDatasets(i)
            colors(i, :) = [0.8 0.8 0.8]; % Gray for empty datasets
        else
            colors(i, :) = originalColor;
        end
    end
elseif size(colors, 1) < nDatasets
    % Handle provided colors, ensuring empty datasets get gray
    originalColors = colors;
    colors = zeros(nDatasets, 3);
    nonEmptyCounter = 1;
    for i = 1:nDatasets
        if emptyDatasets(i)
            colors(i, :) = [0.8 0.8 0.8]; % Gray for empty datasets
        else
            if nonEmptyCounter <= size(originalColors, 1)
                colors(i, :) = originalColors(nonEmptyCounter, :);
            else
                % Recycle colors if needed
                colIdx = mod(nonEmptyCounter-1, size(originalColors, 1)) + 1;
                colors(i, :) = originalColors(colIdx, :);
            end
            nonEmptyCounter = nonEmptyCounter + 1;
        end
    end
end

% Generate default labels if not provided
if isempty(labels)
    labels = cell(1, nDatasets);
    for i = 1:nDatasets
        labels{i} = num2str(i);
    end
elseif length(labels) < nDatasets
    % Extend labels if too few provided
    originalLabels = labels;
    labels = cell(1, nDatasets);
    for i = 1:length(originalLabels)
        labels{i} = originalLabels{i};
    end
    for i = length(originalLabels)+1:nDatasets
        labels{i} = num2str(i);
    end
end

% Set positions for boxplots if not provided
if isempty(position)
    position = 1:nDatasets;
elseif length(position) ~= nDatasets
    position = 1:nDatasets;
end

% Modify labels for empty datasets
if plotLabels
    for i = 1:nDatasets
        if emptyDatasets(i)
            labels{i} = [labels{i} ' (empty)'];
        end
    end
end

hold on

% Initialize arrays for scatter plot points
x = zeros(nDatasets, size(dataMatrix, 1));
y = zeros(nDatasets, size(dataMatrix, 1));

% Plot scatter points for each dataset
for iBox = 1:nDatasets
    % Add points to boxplot graph for non-empty datasets
    if ~emptyDatasets(iBox)
        % Calculate position for scatter points with jitter
        x(iBox, :) = position(iBox) + (rand(size(dataMatrix, 1), 1) - 0.5) * 0.4;
        y(iBox, :) = dataMatrix(:, iBox);
        
        % Plot data points with customized size and alpha
        scatter(x(iBox, ~isnan(y(iBox, :))), y(iBox, ~isnan(y(iBox, :))), point_size, colors(iBox, :), 'filled', 'MarkerFaceAlpha', alpha_points);
    end
end

% Plot lines linking participants between boxplots
if plotLines && nDatasets > 1
    for i = 1:size(dataMatrix, 1)
        % Only plot lines where data points exist (not NaN)
        validPoints = find(~isnan(y(:, i)));
        if length(validPoints) > 1
            plot(x(validPoints, i), y(validPoints, i), 'Color', [.7 .7 .7 alpha_lines], 'LineWidth', line_width * 0.67);
        end
    end
end

% Plot using Matlab's boxplot function
if blackBox
    boxCol = 'k';
else
    boxCol = colors;
end
if plotLabels
    hBoxplot = boxplot(dataMatrix, 'Labels', labels, 'Colors', boxCol, 'positions', position);
else
    hBoxplot = boxplot(dataMatrix, 'Colors', boxCol, 'positions', position);
end

% Apply axis settings
if axisSquare
    axis square
end

if ~isempty(x_lim)
    xlim(x_lim);
else
    xlim([min(position)-0.5, max(position)+0.5]);
end

if ~isempty(y_lim)
    ylim(y_lim);
else
    % Get current y limits and make sure they include zero for empty datasets
    yl = ylim;
    if yl(1) > 0 || yl(2) < 0
        if any(emptyDatasets)
            % Include zero in y-limits if there are empty datasets
            ylim([min(yl(1), 0), max(yl(2), 0)]);
        end
    end
end

% Apply line width setting
set(hBoxplot, 'Linewidth', line_width);

% Change outliers appearance
hOutliers = findobj(gca, 'Tag', 'Outliers');
set(hOutliers, 'MarkerEdgeColor', [.5 .5 .5], 'MarkerSize', point_size * 0.2);

% Change Box appearance - first get all box elements
hBox = findobj(gca, 'Tag', 'Box');
hMedian = findobj(gca, 'Tag', 'Median');
hWhisker = findobj(gca, 'Tag', 'Whisker');

% We need to determine which box corresponds to which dataset position
% Extract positions from axis tick labels
axh = gca;
xLabels = get(axh, 'XTickLabel');
xTicks = get(axh, 'XTick');
boxPositionMap = containers.Map('KeyType', 'double', 'ValueType', 'double');

% Create mapping between box positions and dataset indices
for i = 1:length(xTicks)
    if i <= length(position)
        boxPositionMap(i) = xTicks(i);
    end
end

% Apply colors to boxes directly after plotting
for i = 1:length(hBox)
    try
        boxXData = get(hBox(i), 'XData');
        if ~isempty(boxXData)
            % Identify which dataset this box belongs to by position
            boxPos = round(mean(boxXData));
            datasetIndex = find(position == boxPos, 1);
            
            if ~isempty(datasetIndex) && ~emptyDatasets(datasetIndex)
                % Create patch with the box data and the appropriate color
                patch(boxXData, get(hBox(i), 'YData'), colors(datasetIndex, :), 'FaceAlpha', alpha_lines, 'LineStyle', 'none');
            end
        end
    catch
        % Skip on error
        continue; 
    end
end


% % Apply axis settings
% if axisSquare
%     axis square
% end
% 
% if ~isempty(x_lim)
%     xlim(x_lim);
% else
%     xlim([min(position)-0.5, max(position)+0.5]);
% end
% 
% if ~isempty(y_lim)
%     ylim(y_lim);
% else
%     % Get current y limits and make sure they include zero for empty datasets
%     yl = ylim;
%     if yl(1) > 0 || yl(2) < 0
%         if any(emptyDatasets)
%             % Include zero in y-limits if there are empty datasets
%             ylim([min(yl(1), 0), max(yl(2), 0)]);
%         end
%     end
% end

% Add labels and title
if ~isempty(x_label) && ~strcmp(x_label{1}, '')
    xlabel(x_label{1});
end

if ~isempty(y_label) && ~strcmp(y_label{1}, '')
    ylabel(y_label{1});
end

if ~isempty(title_text) && ~isempty(title_text{1})
    title(title_text{1});
end
% Apply line width setting
set(hBoxplot, 'Linewidth', line_width);

% Set font size
set(gca, 'FontSize', font_size);

hold off

end